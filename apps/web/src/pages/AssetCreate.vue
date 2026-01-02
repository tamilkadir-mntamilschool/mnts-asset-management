<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import QRCode from 'qrcode'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'
import { useSessionStore } from '@/stores/session'

type AssetRecord = {
  id: string
  asset_code: string
  name: string
  category: string | null
  location: string | null
  description: string | null
  updated_at: string
  permanent_owner_id: string | null
  image_paths: string[] | null
}

type Asset = {
  id: string
  assetCode: string
  name: string
  category: string
  location: string
  description: string
  updatedAt: string
  permanentOwnerId: string | null
  imagePaths: string[]
}

type ProfileRecord = {
  id: string
  full_name: string | null
  email: string | null
}

type Profile = {
  id: string
  fullName: string | null
  email: string | null
}

type ImagePreview = {
  file: File
  url: string
}

const sessionStore = useSessionStore()
const router = useRouter()

const form = ref({
  name: '',
  category: '',
  location: '',
  description: '',
  permanentOwnerId: '',
})

const asset = ref<Asset | null>(null)
const profiles = ref<Profile[]>([])
const categories = ref<string[]>([])
const locations = ref<string[]>([])
const ownerSearch = ref('')
const categorySearch = ref('')
const locationSearch = ref('')
const qrDataUrl = ref<string | null>(null)
const imagePreviews = ref<ImagePreview[]>([])
const uploadedImageUrls = ref<string[]>([])
const loading = ref(false)
const error = ref<string | null>(null)
const uploadError = ref<string | null>(null)

const assetUrl = computed(() => {
  if (!asset.value) return ''
  return `${window.location.origin}/assets/code/${asset.value.assetCode}`
})

const mapAssetRecord = (record: AssetRecord): Asset => ({
  id: record.id,
  assetCode: record.asset_code,
  name: record.name,
  category: record.category ?? 'Uncategorized',
  location: record.location ?? 'Unassigned',
  description: record.description ?? '',
  updatedAt: record.updated_at?.slice(0, 10) ?? '—',
  permanentOwnerId: record.permanent_owner_id ?? null,
  imagePaths: record.image_paths ?? [],
})

const mapProfileRecord = (record: ProfileRecord): Profile => ({
  id: record.id,
  fullName: record.full_name,
  email: record.email,
})

const profileLabel = (profile: Profile | undefined) => {
  if (!profile) return null
  return profile.fullName || profile.email
}

const filteredOwnerProfiles = computed(() => {
  const query = ownerSearch.value.trim().toLowerCase()
  if (!query) return profiles.value
  return profiles.value.filter((profile) => {
    const searchText = `${profile.fullName ?? ''} ${profile.email ?? ''} ${profile.id}`.toLowerCase()
    return searchText.includes(query)
  })
})

const filteredCategories = computed(() => {
  const query = categorySearch.value.trim().toLowerCase()
  if (!query) return categories.value
  return categories.value.filter((category) => category.toLowerCase().includes(query))
})

const filteredLocations = computed(() => {
  const query = locationSearch.value.trim().toLowerCase()
  if (!query) return locations.value
  return locations.value.filter((location) => location.toLowerCase().includes(query))
})

const shouldShowCreateCategory = computed(() => {
  const value = categorySearch.value.trim()
  if (!value) return false
  return !categories.value.some((category) => category.toLowerCase() === value.toLowerCase())
})

const shouldShowCreateLocation = computed(() => {
  const value = locationSearch.value.trim()
  if (!value) return false
  return !locations.value.some((location) => location.toLowerCase() === value.toLowerCase())
})

const fetchProfilesList = async () => {
  if (!isSupabaseConfigured) return

  const { data, error: profilesError } = await supabase
    .from('profiles')
    .select('id, full_name, email')
    .order('full_name', { ascending: true, nullsFirst: false })

  if (profilesError) {
    error.value = profilesError.message
  } else {
    profiles.value = (data as ProfileRecord[]).map(mapProfileRecord)
  }
}

const fetchExistingValues = async () => {
  if (!isSupabaseConfigured) return

  const { data, error: valuesError } = await supabase
    .from('assets')
    .select('category, location')

  if (valuesError) {
    error.value = valuesError.message
    return
  }

  const categorySet = new Set<string>()
  const locationSet = new Set<string>()
  ;(data as { category: string | null; location: string | null }[]).forEach((entry) => {
    if (entry.category?.trim()) categorySet.add(entry.category.trim())
    if (entry.location?.trim()) locationSet.add(entry.location.trim())
  })

  categories.value = Array.from(categorySet).sort((a, b) => a.localeCompare(b))
  locations.value = Array.from(locationSet).sort((a, b) => a.localeCompare(b))
}

const refreshImages = async (paths: string[]) => {
  if (!isSupabaseConfigured || paths.length === 0) {
    uploadedImageUrls.value = []
    return
  }

  const urls: string[] = []
  for (const path of paths) {
    const { data, error: urlError } = await supabase.storage.from('asset-images').createSignedUrl(path, 3600)
    if (!urlError && data?.signedUrl) {
      urls.push(data.signedUrl)
    }
  }
  uploadedImageUrls.value = urls
}

const clearImagePreviews = () => {
  imagePreviews.value.forEach((preview) => URL.revokeObjectURL(preview.url))
  imagePreviews.value = []
}

const handleImageSelection = (event: Event) => {
  const input = event.target as HTMLInputElement
  const files = input.files
  if (!files || files.length === 0) return

  clearImagePreviews()
  imagePreviews.value = Array.from(files).map((file) => ({
    file,
    url: URL.createObjectURL(file),
  }))

  if (input) {
    input.value = ''
  }
}

const removeImage = (index: number) => {
  const preview = imagePreviews.value[index]
  if (preview) {
    URL.revokeObjectURL(preview.url)
    imagePreviews.value.splice(index, 1)
  }
}

const resetForm = () => {
  form.value = {
    name: '',
    category: '',
    location: '',
    description: '',
    permanentOwnerId: '',
  }
  asset.value = null
  error.value = null
  uploadError.value = null
  qrDataUrl.value = null
  categorySearch.value = ''
  locationSearch.value = ''
  uploadedImageUrls.value = []
  clearImagePreviews()
}

const createAsset = async () => {
  const trimmedName = form.value.name.trim()
  if (!trimmedName || !isSupabaseConfigured) return

  loading.value = true
  error.value = null
  uploadError.value = null

  const { data, error: insertError } = await supabase
    .from('assets')
    .insert({
      name: trimmedName,
      category: form.value.category.trim() || null,
      location: form.value.location.trim() || null,
      description: form.value.description.trim() || null,
      permanent_owner_id: form.value.permanentOwnerId || null,
    })
    .select('id, asset_code, name, category, location, description, updated_at, permanent_owner_id, image_paths')
    .single()

  if (insertError || !data) {
    error.value = insertError?.message ?? 'Unable to create asset.'
    loading.value = false
    return
  }

  asset.value = mapAssetRecord(data as AssetRecord)
  const trimmedCategory = form.value.category.trim()
  const trimmedLocation = form.value.location.trim()
  if (trimmedCategory && !categories.value.some((category) => category.toLowerCase() === trimmedCategory.toLowerCase())) {
    categories.value = [...categories.value, trimmedCategory].sort((a, b) => a.localeCompare(b))
  }
  if (trimmedLocation && !locations.value.some((location) => location.toLowerCase() === trimmedLocation.toLowerCase())) {
    locations.value = [...locations.value, trimmedLocation].sort((a, b) => a.localeCompare(b))
  }

  if (imagePreviews.value.length) {
    const uploadedPaths: string[] = []
    for (const preview of imagePreviews.value) {
      const sanitizedName = preview.file.name.replace(/\s+/g, '-')
      const path = `assets/${asset.value.id}/${Date.now()}-${sanitizedName}`
      const { error: uploadErr } = await supabase.storage.from('asset-images').upload(path, preview.file, {
        upsert: false,
      })
      if (uploadErr) {
        uploadError.value = uploadErr.message
        break
      }
      uploadedPaths.push(path)
    }

    if (uploadedPaths.length) {
      const { data: updateData, error: updateError } = await supabase
        .from('assets')
        .update({ image_paths: uploadedPaths })
        .eq('id', asset.value.id)
        .select('id, asset_code, name, category, location, description, updated_at, permanent_owner_id, image_paths')
        .single()

      if (updateError) {
        uploadError.value = updateError.message
      } else if (updateData) {
        asset.value = mapAssetRecord(updateData as AssetRecord)
        await refreshImages(asset.value.imagePaths)
      }
    }
  }

  loading.value = false
}

const setOwnerToMe = () => {
  if (!sessionStore.user) return
  form.value.permanentOwnerId = sessionStore.user.id
}

const addCategoryFromSearch = () => {
  const value = categorySearch.value.trim()
  if (!value) return
  if (!categories.value.some((category) => category.toLowerCase() === value.toLowerCase())) {
    categories.value = [...categories.value, value].sort((a, b) => a.localeCompare(b))
  }
  form.value.category = value
}

const addLocationFromSearch = () => {
  const value = locationSearch.value.trim()
  if (!value) return
  if (!locations.value.some((location) => location.toLowerCase() === value.toLowerCase())) {
    locations.value = [...locations.value, value].sort((a, b) => a.localeCompare(b))
  }
  form.value.location = value
}

const printQr = () => {
  if (!asset.value) return
  window.print()
}

const goBack = () => {
  router.push({ name: 'assets' })
}

watch(
  () => asset.value?.assetCode,
  async (code) => {
    if (!code) {
      qrDataUrl.value = null
      return
    }
    try {
      qrDataUrl.value = await QRCode.toDataURL(assetUrl.value, { width: 240, margin: 2 })
    } catch (qrError) {
      console.error(qrError)
      qrDataUrl.value = null
    }
  }
)

onMounted(async () => {
  await sessionStore.init()
  await fetchProfilesList()
  await fetchExistingValues()
})

onBeforeUnmount(() => {
  clearImagePreviews()
})
</script>

<template>
  <div class="mx-auto w-full max-w-6xl px-6 py-10">
    <div class="flex flex-col gap-6">
      <div class="flex flex-wrap items-center justify-between gap-4 print-hide">
        <div>
          <p class="text-xs uppercase tracking-[0.2em] text-slate-300">Create asset</p>
          <h1 class="mt-2 text-3xl font-semibold text-white">Add a new asset</h1>
          <p class="mt-2 text-sm text-slate-200">
            Add core details, assign an owner, and generate a QR code right away.
          </p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <Button
            variant="outline"
            class="border-slate-700/80 bg-slate-900 text-slate-100 hover:bg-slate-800 hover:text-white"
            @click="goBack"
          >
            Back to assets
          </Button>
        </div>
      </div>

      <div v-if="!isSupabaseConfigured" class="rounded-2xl border border-slate-800/80 bg-slate-900/60 p-6 text-sm text-rose-200">
        Supabase is not configured, so assets cannot be saved right now.
      </div>

      <div v-if="error" class="rounded-2xl border border-slate-800/80 bg-slate-900/60 p-4 text-sm text-rose-300">
        {{ error }}
      </div>

      <div class="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
        <div class="rounded-2xl border border-slate-800/80 bg-slate-900/60 p-6 print-hide">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-slate-300">Asset details</p>
              <p class="text-xs text-slate-400">Required fields are marked below.</p>
            </div>
            <Button
              v-if="asset"
              variant="outline"
              class="border-slate-700/80 bg-slate-900 text-slate-100 hover:bg-slate-800 hover:text-white"
              @click="resetForm"
            >
              Create another
            </Button>
          </div>
          <div class="mt-4 grid gap-4 text-sm text-slate-200">
            <div class="grid gap-2">
              <Label for="asset-name">Asset name</Label>
              <Input id="asset-name" v-model="form.name" placeholder="Forklift FL-12" :disabled="loading" />
            </div>
            <div class="grid gap-2">
              <Label for="asset-category">Category</Label>
              <Select v-model="form.category" :disabled="loading">
                <SelectTrigger id="asset-category">
                  <SelectValue placeholder="Select a category" />
                </SelectTrigger>
                <SelectContent>
                  <div class="border-b border-slate-800/80 p-2">
                    <Input
                      v-model="categorySearch"
                      placeholder="Search categories..."
                      @click.stop
                      @keydown.stop
                      @pointerdown.stop
                    />
                  </div>
                  <SelectItem
                    v-for="category in filteredCategories"
                    :key="category"
                    :value="category"
                  >
                    {{ category }}
                  </SelectItem>
                  <button
                    v-if="!filteredCategories.length && shouldShowCreateCategory"
                    class="flex w-full items-center justify-between px-3 py-2 text-left text-emerald-200 transition hover:bg-slate-800/70"
                    type="button"
                    @click="addCategoryFromSearch"
                  >
                    <span>Create “{{ categorySearch.trim() }}”</span>
                    <span class="text-xs text-slate-400">New</span>
                  </button>
                  <div
                    v-else-if="!filteredCategories.length"
                    class="px-3 py-2 text-xs text-slate-400"
                  >
                    No matching categories.
                  </div>
                </SelectContent>
              </Select>
            </div>
            <div class="grid gap-2">
              <Label for="asset-location">Location</Label>
              <Select v-model="form.location" :disabled="loading">
                <SelectTrigger id="asset-location">
                  <SelectValue placeholder="Select a location" />
                </SelectTrigger>
                <SelectContent>
                  <div class="border-b border-slate-800/80 p-2">
                    <Input
                      v-model="locationSearch"
                      placeholder="Search locations..."
                      @click.stop
                      @keydown.stop
                      @pointerdown.stop
                    />
                  </div>
                  <SelectItem
                    v-for="location in filteredLocations"
                    :key="location"
                    :value="location"
                  >
                    {{ location }}
                  </SelectItem>
                  <button
                    v-if="!filteredLocations.length && shouldShowCreateLocation"
                    class="flex w-full items-center justify-between px-3 py-2 text-left text-emerald-200 transition hover:bg-slate-800/70"
                    type="button"
                    @click="addLocationFromSearch"
                  >
                    <span>Create “{{ locationSearch.trim() }}”</span>
                    <span class="text-xs text-slate-400">New</span>
                  </button>
                  <div
                    v-else-if="!filteredLocations.length"
                    class="px-3 py-2 text-xs text-slate-400"
                  >
                    No matching locations.
                  </div>
                </SelectContent>
              </Select>
            </div>
            <div class="grid gap-2">
              <Label for="asset-description">Description</Label>
              <Textarea
                id="asset-description"
                v-model="form.description"
                placeholder="Add any useful context"
                :disabled="loading"
              />
            </div>
            <div class="flex flex-wrap gap-2">
              <Button
                class="bg-amber-300 text-slate-950 hover:bg-amber-200"
                :disabled="loading || !form.name.trim() || !isSupabaseConfigured"
                @click="createAsset"
              >
                {{ asset ? 'Add another asset' : 'Add asset' }}
              </Button>
            </div>
          </div>
        </div>

        <div class="flex flex-col gap-6">
          <div class="rounded-2xl border border-slate-800/80 bg-slate-900/60 p-6 print-hide">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm text-slate-300">Primary owner</p>
                <p class="text-xs text-slate-400">Assign the primary owner for this asset.</p>
              </div>
              <Button
                variant="outline"
                class="border-slate-700/80 bg-slate-900 text-slate-100 hover:bg-slate-800 hover:text-white"
                @click="setOwnerToMe"
              >
                Make me owner
              </Button>
            </div>
            <div class="mt-4 grid gap-2 text-sm text-slate-200">
              <Label for="owner-select">Owner</Label>
              <Select v-model="form.permanentOwnerId" :disabled="loading">
                <SelectTrigger id="owner-select">
                  <SelectValue placeholder="Select a user" />
                </SelectTrigger>
                <SelectContent>
                  <div class="border-b border-slate-800/80 p-2">
                    <Input
                      v-model="ownerSearch"
                      placeholder="Search users..."
                      @click.stop
                      @keydown.stop
                      @pointerdown.stop
                    />
                  </div>
                  <SelectItem
                    v-for="profile in filteredOwnerProfiles"
                    :key="profile.id"
                    :value="profile.id"
                  >
                    {{ profileLabel(profile) ?? profile.id }}
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div class="rounded-2xl border border-slate-800/80 bg-slate-900/60 p-6 print-hide">
            <div>
              <p class="text-sm text-slate-300">Asset images</p>
              <p class="text-xs text-slate-400">Upload one or more optional images.</p>
            </div>
            <div class="mt-4 grid gap-3">
              <Input id="asset-images" type="file" accept="image/*" multiple @change="handleImageSelection" />
              <div v-if="imagePreviews.length" class="grid gap-3 sm:grid-cols-2">
                <div
                  v-for="(preview, index) in imagePreviews"
                  :key="preview.url"
                  class="relative overflow-hidden rounded-xl border border-slate-800/80"
                >
                  <img :src="preview.url" class="h-36 w-full object-cover" alt="Selected asset" />
                  <button
                    class="absolute right-2 top-2 rounded-full bg-slate-950/80 px-2 py-1 text-xs text-slate-100"
                    type="button"
                    @click="removeImage(index)"
                  >
                    Remove
                  </button>
                </div>
              </div>
              <div v-else class="text-xs text-slate-400">No photos added yet.</div>
              <p v-if="uploadError" class="text-xs text-rose-300">
                {{ uploadError }}
              </p>
              <div v-if="uploadedImageUrls.length" class="grid gap-3 sm:grid-cols-2">
                <img
                  v-for="url in uploadedImageUrls"
                  :key="url"
                  :src="url"
                  class="h-36 w-full rounded-xl object-cover"
                  alt="Uploaded asset"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div v-if="asset" class="rounded-3xl border border-slate-800/80 bg-slate-900/60 p-8 print-card">
        <div class="flex flex-wrap items-start justify-between gap-4">
          <div>
            <p class="text-sm text-slate-300">QR code</p>
            <h2 class="mt-2 text-2xl font-semibold text-white">{{ asset.name }}</h2>
            <p class="mt-1 text-xs text-slate-400">{{ asset.assetCode }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2 print-hide">
            <Button
              as-child
              variant="outline"
              class="border-slate-700/80 bg-slate-900 text-slate-100 hover:bg-slate-800 hover:text-white"
            >
              <RouterLink :to="`/assets/${asset.id}`">View asset</RouterLink>
            </Button>
            <Button class="bg-amber-300 text-slate-950 hover:bg-amber-200" @click="printQr">
              Print QR code
            </Button>
          </div>
        </div>
        <div class="mt-6 flex flex-col items-center gap-4 text-center">
          <img v-if="qrDataUrl" :src="qrDataUrl" class="h-56 w-56" alt="Asset QR code" />
          <p class="text-xs text-slate-400">{{ assetUrl }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
@media print {
  :global(body) {
    background: #ffffff;
  }

  .print-hide {
    display: none;
  }

  .print-card {
    border: none;
    background: #ffffff;
    box-shadow: none;
  }
}
</style>
