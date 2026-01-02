<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import QRCode from 'qrcode'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
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
  permanent_owner_id: string
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
  permanentOwnerId: string
  imagePaths: string[]
}

type AssetLoanRecord = {
  id: string
  borrower_id: string
  checked_out_at: string
  checked_in_at: string | null
  notes: string | null
}

type AssetLoan = {
  id: string
  borrowerId: string
  checkedOutAt: string
  checkedInAt: string | null
  notes: string
}

type OwnerHistoryRecord = {
  id: string
  owner_id: string
  changed_at: string
  changed_by: string | null
}

type OwnerHistory = {
  id: string
  ownerId: string
  changedAt: string
  changedBy: string | null
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

const route = useRoute()
const router = useRouter()
const sessionStore = useSessionStore()

const asset = ref<Asset | null>(null)
const activeLoan = ref<AssetLoan | null>(null)
const loanHistory = ref<AssetLoan[]>([])
const ownerHistory = ref<OwnerHistory[]>([])
const imageUrls = ref<string[]>([])
const qrDataUrl = ref<string | null>(null)
const ownerSelection = ref('')
const profiles = ref<Profile[]>([])
const profileLookup = ref<Record<string, Profile>>({})
const checkoutNotes = ref('')
const borrowerSelection = ref('')
const ownerSearch = ref('')
const borrowerSearch = ref('')
const uploadError = ref<string | null>(null)
const loading = ref(false)
const error = ref<string | null>(null)
const isEditing = ref(false)
const editAsset = ref({
  name: '',
  category: '',
  location: '',
  description: '',
})

const assetIdParam = computed(() => route.params.id as string | undefined)
const assetCodeParam = computed(() => route.params.code as string | undefined)

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
  permanentOwnerId: record.permanent_owner_id,
  imagePaths: record.image_paths ?? [],
})

const mapLoanRecord = (record: AssetLoanRecord): AssetLoan => ({
  id: record.id,
  borrowerId: record.borrower_id,
  checkedOutAt: record.checked_out_at,
  checkedInAt: record.checked_in_at,
  notes: record.notes ?? '',
})

const mapOwnerHistoryRecord = (record: OwnerHistoryRecord): OwnerHistory => ({
  id: record.id,
  ownerId: record.owner_id,
  changedAt: record.changed_at,
  changedBy: record.changed_by,
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

const profileSearchText = (profile: Profile) => {
  return `${profile.fullName ?? ''} ${profile.email ?? ''} ${profile.id}`.toLowerCase()
}

const profileName = (userId: string | null | undefined) => {
  if (!userId) return '—'
  const profile = profileLookup.value[userId] ?? profiles.value.find((entry) => entry.id === userId)
  return profileLabel(profile) ?? userId
}

const filteredOwnerProfiles = computed(() => {
  const query = ownerSearch.value.trim().toLowerCase()
  if (!query) return profiles.value
  return profiles.value.filter((profile) => profileSearchText(profile).includes(query))
})

const filteredBorrowerProfiles = computed(() => {
  const query = borrowerSearch.value.trim().toLowerCase()
  if (!query) return profiles.value
  return profiles.value.filter((profile) => profileSearchText(profile).includes(query))
})

const refreshImages = async (paths: string[]) => {
  if (!isSupabaseConfigured || paths.length === 0) {
    imageUrls.value = []
    return
  }

  const urls: string[] = []
  for (const path of paths) {
    const { data, error: urlError } = await supabase.storage.from('asset-images').createSignedUrl(path, 3600)
    if (!urlError && data?.signedUrl) {
      urls.push(data.signedUrl)
    }
  }
  imageUrls.value = urls
}

const setEditFromAsset = () => {
  if (!asset.value) return
  editAsset.value = {
    name: asset.value.name,
    category: asset.value.category === 'Uncategorized' ? '' : asset.value.category,
    location: asset.value.location === 'Unassigned' ? '' : asset.value.location,
    description: asset.value.description ?? '',
  }
}

const fetchAsset = async () => {
  if (!isSupabaseConfigured) {
    error.value = 'Supabase is not configured.'
    return
  }

  loading.value = true
  error.value = null

  const query = supabase
    .from('assets')
    .select('id, asset_code, name, category, location, description, updated_at, permanent_owner_id, image_paths')

  const { data, error: fetchError } = assetCodeParam.value
    ? await query.eq('asset_code', assetCodeParam.value).single()
    : await query.eq('id', assetIdParam.value).single()

  if (fetchError || !data) {
    error.value = fetchError?.message ?? 'Asset not found.'
    asset.value = null
  } else {
    asset.value = mapAssetRecord(data as AssetRecord)
    ownerSelection.value = asset.value.permanentOwnerId
    if (!isEditing.value) {
      setEditFromAsset()
    }
    await refreshImages(asset.value.imagePaths)
  }

  loading.value = false
}

const fetchLoans = async () => {
  if (!asset.value || !isSupabaseConfigured) return

  const { data, error: loansError } = await supabase
    .from('asset_loans')
    .select('id, borrower_id, checked_out_at, checked_in_at, notes')
    .eq('asset_id', asset.value.id)
    .order('checked_out_at', { ascending: false })

  if (loansError) {
    error.value = loansError.message
    loanHistory.value = []
    activeLoan.value = null
  } else {
    const mapped = (data as AssetLoanRecord[]).map(mapLoanRecord)
    loanHistory.value = mapped
    activeLoan.value = mapped.find((loan) => !loan.checkedInAt) ?? null
  }
}

const fetchOwnerHistory = async () => {
  if (!asset.value || !isSupabaseConfigured) return

  const { data, error: historyError } = await supabase
    .from('asset_owner_history')
    .select('id, owner_id, changed_at, changed_by')
    .eq('asset_id', asset.value.id)
    .order('changed_at', { ascending: false })

  if (historyError) {
    error.value = historyError.message
    ownerHistory.value = []
  } else {
    ownerHistory.value = (data as OwnerHistoryRecord[]).map(mapOwnerHistoryRecord)
  }
}

const fetchProfiles = async (ids: string[]) => {
  if (!isSupabaseConfigured || ids.length === 0) return

  const uniqueIds = Array.from(new Set(ids))
  const { data, error: profilesError } = await supabase
    .from('profiles')
    .select('id, full_name, email')
    .in('id', uniqueIds)

  if (profilesError) {
    error.value = profilesError.message
    return
  }

  const mapped = (data as ProfileRecord[]).map(mapProfileRecord)
  const nextLookup: Record<string, Profile> = { ...profileLookup.value }
  for (const profile of mapped) {
    nextLookup[profile.id] = profile
  }
  profileLookup.value = nextLookup
}

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

const refreshAssetData = async () => {
  await fetchAsset()
  await fetchLoans()
  await fetchOwnerHistory()
  const ids: string[] = []
  if (asset.value) ids.push(asset.value.permanentOwnerId)
  loanHistory.value.forEach((loan) => ids.push(loan.borrowerId))
  ownerHistory.value.forEach((entry) => {
    ids.push(entry.ownerId)
    if (entry.changedBy) ids.push(entry.changedBy)
  })
  await fetchProfiles(ids)
}

const checkOutAsset = async () => {
  if (!asset.value || !sessionStore.user || !isSupabaseConfigured) return

  const borrowerId = borrowerSelection.value || sessionStore.user.id
  loading.value = true
  error.value = null
  const { error: checkoutError } = await supabase.from('asset_loans').insert({
    asset_id: asset.value.id,
    borrower_id: borrowerId,
    notes: checkoutNotes.value.trim() || null,
  })

  if (checkoutError) {
    error.value = checkoutError.message
  } else {
    checkoutNotes.value = ''
    await fetchLoans()
  }
  loading.value = false
}

const checkInAsset = async () => {
  if (!activeLoan.value || !isSupabaseConfigured) return

  loading.value = true
  error.value = null
  const { error: checkinError } = await supabase
    .from('asset_loans')
    .update({ checked_in_at: new Date().toISOString() })
    .eq('id', activeLoan.value.id)

  if (checkinError) {
    error.value = checkinError.message
  } else {
    await fetchLoans()
  }
  loading.value = false
}

const updateOwner = async (ownerId: string) => {
  if (!asset.value || !isSupabaseConfigured) return

  const trimmedOwner = ownerId.trim()
  if (!trimmedOwner) return

  loading.value = true
  error.value = null
  const { data, error: ownerError } = await supabase
    .from('assets')
    .update({ permanent_owner_id: trimmedOwner })
    .eq('id', asset.value.id)
    .select('id, asset_code, name, category, location, description, updated_at, permanent_owner_id, image_paths')
    .single()

  if (ownerError) {
    error.value = ownerError.message
  } else if (data) {
    asset.value = mapAssetRecord(data as AssetRecord)
    ownerSelection.value = asset.value.permanentOwnerId
    await fetchOwnerHistory()
  }
  loading.value = false
}

const saveAssetDetails = async () => {
  if (!asset.value || !isSupabaseConfigured) return
  const trimmedName = editAsset.value.name.trim()
  if (!trimmedName) return

  loading.value = true
  error.value = null
  const { data, error: updateError } = await supabase
    .from('assets')
    .update({
      name: trimmedName,
      category: editAsset.value.category.trim() || null,
      location: editAsset.value.location.trim() || null,
      description: editAsset.value.description?.trim() || null,
    })
    .eq('id', asset.value.id)
    .select('id, asset_code, name, category, location, description, updated_at, permanent_owner_id, image_paths')
    .single()

  if (updateError) {
    error.value = updateError.message
  } else if (data) {
    asset.value = mapAssetRecord(data as AssetRecord)
    setEditFromAsset()
    isEditing.value = false
  }
  loading.value = false
}

const startEditing = () => {
  setEditFromAsset()
  isEditing.value = true
}

const cancelEditing = () => {
  setEditFromAsset()
  isEditing.value = false
}

const setOwnerToMe = async () => {
  if (!sessionStore.user) return
  await updateOwner(sessionStore.user.id)
}

const handleImageUpload = async (event: Event) => {
  if (!asset.value || !isSupabaseConfigured) return

  const input = event.target as HTMLInputElement
  const files = input.files
  if (!files || files.length === 0) return

  uploadError.value = null
  loading.value = true
  const uploadedPaths: string[] = []

  for (const file of Array.from(files)) {
    const sanitizedName = file.name.replace(/\s+/g, '-')
    const path = `assets/${asset.value.id}/${Date.now()}-${sanitizedName}`
    const { error: uploadErr } = await supabase.storage.from('asset-images').upload(path, file, {
      upsert: false,
    })
    if (uploadErr) {
      uploadError.value = uploadErr.message
      break
    }
    uploadedPaths.push(path)
  }

  if (uploadedPaths.length) {
    const nextPaths = [...asset.value.imagePaths, ...uploadedPaths]
    const { data, error: updateError } = await supabase
      .from('assets')
      .update({ image_paths: nextPaths })
      .eq('id', asset.value.id)
      .select('id, asset_code, name, category, location, description, updated_at, permanent_owner_id, image_paths')
      .single()

    if (updateError) {
      uploadError.value = updateError.message
    } else if (data) {
      asset.value = mapAssetRecord(data as AssetRecord)
      await refreshImages(asset.value.imagePaths)
    }
  }

  if (input) {
    input.value = ''
  }
  loading.value = false
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

watch([assetIdParam, assetCodeParam], () => {
  void refreshAssetData()
})

onMounted(async () => {
  await sessionStore.init()
  if (sessionStore.user) {
    borrowerSelection.value = sessionStore.user.id
  }
  await fetchProfilesList()
  await refreshAssetData()
})
</script>

<template>
  <div class="mx-auto w-full max-w-6xl px-6 py-10">
    <div class="flex flex-col gap-6 pb-10">
      <div class="flex flex-col gap-4 rounded-3xl border border-slate-800/80 bg-slate-900/60 p-8 shadow-lg shadow-slate-950/30">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p class="text-xs uppercase tracking-[0.2em] text-slate-300">Asset detail</p>
            <h1 class="mt-2 text-3xl font-semibold text-white">{{ asset?.name ?? 'Loading asset' }}</h1>
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
        <div v-if="error" class="text-sm text-rose-300">
          {{ error }}
        </div>
      </div>

      <div v-if="loading" class="text-sm text-slate-300">Loading asset data...</div>

      <div v-if="asset" class="grid gap-6 lg:grid-cols-[1.2fr_0.8fr]">
        <div class="order-1 rounded-2xl border border-slate-800/80 bg-slate-900/60 p-6">
          <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <p class="text-sm text-slate-300">Asset code</p>
              <p class="text-xl font-semibold text-white">{{ asset.assetCode }}</p>
              <p class="mt-1 text-xs text-slate-400">Last updated: {{ asset.updatedAt }}</p>
            </div>
            <div class="flex items-center gap-2">
              <Button
                v-if="!isEditing"
                variant="outline"
                class="border-slate-700/80 bg-slate-900 text-slate-100 hover:bg-slate-800 hover:text-white"
                @click="startEditing"
              >
                Edit details
              </Button>
            </div>
          </div>
          <div v-if="isEditing" class="mt-4 grid gap-4 text-sm text-slate-200 sm:grid-cols-2">
            <div class="grid gap-2">
              <Label for="edit-name">Name</Label>
              <Input id="edit-name" v-model="editAsset.name" />
            </div>
            <div class="grid gap-2">
              <Label for="edit-category">Category</Label>
              <Input id="edit-category" v-model="editAsset.category" />
            </div>
            <div class="grid gap-2">
              <Label for="edit-location">Location</Label>
              <Input id="edit-location" v-model="editAsset.location" />
            </div>
            <div class="grid gap-2 sm:col-span-2">
              <Label for="edit-description">Description</Label>
              <Textarea id="edit-description" v-model="editAsset.description" />
            </div>
            <div class="flex flex-wrap gap-2 sm:col-span-2">
              <Button class="bg-amber-300 text-slate-950 hover:bg-amber-200" @click="saveAssetDetails">
                Save changes
              </Button>
              <Button
                variant="outline"
                class="border-slate-700/80 bg-slate-900 text-slate-100 hover:bg-slate-800 hover:text-white"
                @click="cancelEditing"
              >
                Cancel
              </Button>
            </div>
          </div>
          <dl v-else class="mt-4 grid gap-4 text-sm text-slate-200 sm:grid-cols-2">
            <div>
              <dt class="text-xs uppercase tracking-[0.18em] text-slate-400">Category</dt>
              <dd class="mt-1">{{ asset.category }}</dd>
            </div>
            <div>
              <dt class="text-xs uppercase tracking-[0.18em] text-slate-400">Location</dt>
              <dd class="mt-1">{{ asset.location }}</dd>
            </div>
            <div class="sm:col-span-2">
              <dt class="text-xs uppercase tracking-[0.18em] text-slate-400">Description</dt>
              <dd class="mt-1 whitespace-pre-line">{{ asset.description || '—' }}</dd>
            </div>
          </dl>
        </div>

        <div class="order-2 rounded-2xl border border-slate-800/80 bg-slate-900/60 p-6 lg:col-start-2 lg:row-start-1">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm text-slate-300">Asset images</p>
              <p class="text-xs text-slate-400">Upload one or more optional images for this asset.</p>
            </div>
          </div>
          <div class="mt-4 grid gap-3">
            <div v-if="imageUrls.length" class="grid gap-3 sm:grid-cols-2">
              <img
                v-for="url in imageUrls"
                :key="url"
                :src="url"
                class="h-40 w-full rounded-xl object-cover"
                alt="Asset image"
              />
            </div>
            <p v-else class="text-xs text-slate-400">No images uploaded yet.</p>
            <Input id="asset-images" type="file" accept="image/*" multiple @change="handleImageUpload" />
            <p v-if="uploadError" class="text-sm text-rose-300">
              {{ uploadError }}
            </p>
          </div>
        </div>

        <div class="order-3 rounded-2xl border border-slate-800/80 bg-slate-900/60 p-6">
          <div class="flex items-start justify-between gap-4">
            <div>
              <p class="text-sm text-slate-300">Availability</p>
              <p class="text-lg font-semibold text-white">
                {{ activeLoan ? 'Checked out' : 'Available' }}
              </p>
              <p v-if="activeLoan" class="text-xs text-slate-400">
                Borrower: {{ profileName(activeLoan.borrowerId) }}
              </p>
            </div>
            <Badge
              variant="outline"
              :class="activeLoan ? 'border-amber-400/40 bg-amber-400/15 text-amber-100' : 'border-emerald-400/40 bg-emerald-400/15 text-emerald-100'"
            >
              {{ activeLoan ? 'Checked out' : 'Available' }}
            </Badge>
          </div>
          <div class="mt-4 grid gap-3 sm:grid-cols-[1fr_auto] sm:items-end">
            <div class="grid gap-2">
              <Label for="borrower-select">Check out to</Label>
              <Select v-model="borrowerSelection" :disabled="Boolean(activeLoan)">
                <SelectTrigger id="borrower-select">
                  <SelectValue placeholder="Select a borrower" />
                </SelectTrigger>
                <SelectContent>
                  <div class="border-b border-slate-800/80 p-2">
                    <Input
                      v-model="borrowerSearch"
                      placeholder="Search users..."
                      @click.stop
                      @keydown.stop
                      @pointerdown.stop
                    />
                  </div>
                  <SelectItem
                    v-for="profile in filteredBorrowerProfiles"
                    :key="profile.id"
                    :value="profile.id"
                  >
                    {{ profileLabel(profile) ?? profile.id }}
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>
            <Button
              v-if="!activeLoan"
              class="bg-amber-300 text-slate-950 hover:bg-amber-200"
              @click="checkOutAsset"
            >
              Check out
            </Button>
            <Button
              v-else
              variant="outline"
              class="border-slate-700/80 bg-slate-900 text-slate-100 hover:bg-slate-800 hover:text-white"
              @click="checkInAsset"
            >
              Check in
            </Button>
          </div>
          <div class="mt-3 grid gap-2">
            <Label for="loan-notes">Checkout notes</Label>
            <Textarea
              id="loan-notes"
              v-model="checkoutNotes"
              placeholder="Add any checkout details"
              :disabled="Boolean(activeLoan)"
            />
          </div>
          <div v-if="loanHistory.length" class="mt-4 space-y-2 text-sm text-slate-200">
            <p class="text-xs uppercase tracking-[0.18em] text-slate-400">Loan history</p>
            <div
              v-for="loan in loanHistory"
              :key="loan.id"
              class="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-slate-800/80 bg-slate-900/50 px-3 py-2"
            >
              <div class="flex flex-col gap-1">
                <span>{{ profileName(loan.borrowerId) }}</span>
                <span v-if="loan.notes" class="text-xs text-slate-300">
                  Notes: {{ loan.notes }}
                </span>
              </div>
              <span class="text-xs text-slate-400">
                {{ loan.checkedOutAt.slice(0, 10) }} → {{ loan.checkedInAt?.slice(0, 10) ?? 'Active' }}
              </span>
            </div>
          </div>
        </div>

        <div class="order-4 rounded-2xl border border-slate-800/80 bg-slate-900/60 p-6">
          <div class="flex flex-col gap-3">
            <div class="flex items-start justify-between">
              <div>
                <p class="text-sm text-slate-300">Primary owner</p>
                <p class="text-base font-semibold text-white">{{ profileName(asset.permanentOwnerId) }}</p>
              </div>
              <Button
                variant="outline"
                class="border-slate-700/80 bg-slate-900 text-slate-100 hover:bg-slate-800 hover:text-white"
                @click="setOwnerToMe"
              >
                Assign to me
              </Button>
            </div>
            <div class="grid gap-3 sm:grid-cols-[1fr_auto] sm:items-end">
              <div class="grid gap-2">
                <Label for="owner-select">Change owner</Label>
                <Select v-model="ownerSelection">
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
              <Button class="bg-amber-300 text-slate-950 hover:bg-amber-200" @click="updateOwner(ownerSelection)">
                Update owner
              </Button>
            </div>
            <div class="mt-2 text-xs text-slate-400">
              Owner history updates automatically when the owner changes.
            </div>
            <div v-if="ownerHistory.length" class="mt-4 space-y-2 text-sm text-slate-200">
              <p class="text-xs uppercase tracking-[0.18em] text-slate-400">Owner history</p>
              <div
                v-for="entry in ownerHistory"
                :key="entry.id"
                class="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-slate-800/80 bg-slate-900/50 px-3 py-2"
              >
                <span>Owner: {{ profileName(entry.ownerId) }}</span>
                <span class="text-xs text-slate-400">{{ entry.changedAt.slice(0, 10) }}</span>
              </div>
            </div>
          </div>
        </div>

        <div class="order-5 rounded-2xl border border-slate-800/80 bg-slate-900/60 p-6">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <p class="text-sm text-slate-300">QR code</p>
              <p class="text-xs text-slate-400">Scan to open this asset in MNTS Asset Management (login required).</p>
            </div>
            <Button
              v-if="asset"
              as-child
              class="bg-amber-300 text-slate-950 hover:bg-amber-200"
            >
              <RouterLink :to="`/assets/${asset.id}/print`">Print QR code</RouterLink>
            </Button>
          </div>
          <div class="mt-4 flex items-center justify-center rounded-2xl border border-slate-800/80 bg-slate-950/60 p-6">
            <img v-if="qrDataUrl" :src="qrDataUrl" class="h-48 w-48" alt="Asset QR code" />
            <div v-else class="text-xs text-slate-400">Generating QR...</div>
          </div>
          <div class="mt-4 rounded-xl border border-slate-800/80 bg-slate-950/50 p-3 text-xs text-slate-300">
            {{ assetUrl }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
