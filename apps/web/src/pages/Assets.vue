<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'
import SidebarLayout from '../layouts/SidebarLayout.vue'

type AssetStatus = 'Operational' | 'Needs Service' | 'Offline'

type Asset = {
  id: string
  name: string
  category: string
  status: AssetStatus
  location: string
  updatedAt: string
  description?: string
}

type AssetRecord = {
  id: string
  name: string
  category: string | null
  status: AssetStatus
  location: string | null
  description: string | null
  updated_at: string
}

const fallbackAssets: Asset[] = [
  {
    id: 'A-1023',
    name: 'Forklift FL-12',
    category: 'Material Handling',
    status: 'Operational',
    location: 'Dock 2',
    updatedAt: '2025-01-18',
  },
  {
    id: 'A-1041',
    name: 'CNC Router 7B',
    category: 'Fabrication',
    status: 'Needs Service',
    location: 'Plant 1',
    updatedAt: '2025-01-12',
  },
  {
    id: 'A-1078',
    name: 'Chiller Unit 4',
    category: 'Facilities',
    status: 'Offline',
    location: 'Rooftop',
    updatedAt: '2024-12-29',
  },
]

const assets = ref<Asset[]>([])
const loading = ref(false)
const error = ref<string | null>(null)

const search = ref('')
const statusFilter = ref<'all' | AssetStatus>('all')
const isDialogOpen = ref(false)
const isEditDialogOpen = ref(false)
const newAsset = ref({
  name: '',
  category: '',
  status: 'Operational' as AssetStatus,
  location: '',
  description: '',
})
const editAsset = ref({
  id: '',
  name: '',
  category: '',
  status: 'Operational' as AssetStatus,
  location: '',
  description: '',
})

const filteredAssets = computed(() => {
  return assets.value.filter((asset) => {
    const matchesSearch =
      asset.name.toLowerCase().includes(search.value.toLowerCase()) ||
      asset.id.toLowerCase().includes(search.value.toLowerCase()) ||
      asset.location.toLowerCase().includes(search.value.toLowerCase())
    const matchesStatus = statusFilter.value === 'all' || asset.status === statusFilter.value
    return matchesSearch && matchesStatus
  })
})

const activeFilters = computed(() => {
  const filters: { label: string; value: string }[] = []
  const trimmedSearch = search.value.trim()
  if (trimmedSearch) {
    filters.push({ label: 'Search', value: trimmedSearch })
  }
  if (statusFilter.value !== 'all') {
    filters.push({ label: 'Status', value: statusFilter.value })
  }
  return filters
})

const hasActiveFilters = computed(() => activeFilters.value.length > 0)

const mapAssetRecord = (record: AssetRecord): Asset => {
  return {
    id: record.id,
    name: record.name,
    category: record.category ?? 'Uncategorized',
    status: record.status,
    location: record.location ?? 'Unassigned',
    updatedAt: record.updated_at?.slice(0, 10) ?? '—',
    description: record.description ?? '',
  }
}

const fetchAssets = async () => {
  if (!isSupabaseConfigured) {
    assets.value = fallbackAssets
    return
  }

  loading.value = true
  error.value = null

  const { data, error: fetchError } = await supabase
    .from('assets')
    .select('id, name, category, status, location, description, updated_at')
    .order('updated_at', { ascending: false })

  if (fetchError) {
    error.value = fetchError.message
    assets.value = []
  } else {
    assets.value = (data as AssetRecord[]).map(mapAssetRecord)
  }

  loading.value = false
}

const statusBadgeClass = (status: AssetStatus) => {
  if (status === 'Operational') return 'border-emerald-400/40 bg-emerald-400/15 text-emerald-100'
  if (status === 'Needs Service') return 'border-amber-400/50 bg-amber-400/15 text-amber-100'
  return 'border-rose-400/50 bg-rose-500/20 text-rose-100'
}

const clearFilters = () => {
  search.value = ''
  statusFilter.value = 'all'
}

const resetForm = () => {
  newAsset.value = {
    name: '',
    category: '',
    status: 'Operational',
    location: '',
    description: '',
  }
}

const resetEditForm = () => {
  editAsset.value = {
    id: '',
    name: '',
    category: '',
    status: 'Operational',
    location: '',
    description: '',
  }
}

const startEdit = (asset: Asset) => {
  editAsset.value = {
    id: asset.id,
    name: asset.name,
    category: asset.category === 'Uncategorized' ? '' : asset.category,
    status: asset.status,
    location: asset.location === 'Unassigned' ? '' : asset.location,
    description: asset.description ?? '',
  }
  isEditDialogOpen.value = true
}

const addAsset = async () => {
  const trimmedName = newAsset.value.name.trim()
  if (!trimmedName) return

  if (isSupabaseConfigured) {
    loading.value = true
    error.value = null
    const { data, error: insertError } = await supabase
      .from('assets')
      .insert({
        name: trimmedName,
        category: newAsset.value.category || null,
        status: newAsset.value.status,
        location: newAsset.value.location || null,
        description: newAsset.value.description?.trim() || null,
      })
      .select('id, name, category, status, location, description, updated_at')
      .single()

    if (insertError) {
      error.value = insertError.message
      loading.value = false
      return
    }

    if (data) {
      assets.value.unshift(mapAssetRecord(data as AssetRecord))
    }
    loading.value = false
  } else {
    assets.value.unshift({
      id: `A-${Math.floor(1000 + Math.random() * 9000)}`,
      name: trimmedName,
      category: newAsset.value.category || 'Uncategorized',
      status: newAsset.value.status,
      location: newAsset.value.location || 'Unassigned',
      updatedAt: new Date().toISOString().slice(0, 10),
      description: newAsset.value.description?.trim(),
    })
  }

  resetForm()
  isDialogOpen.value = false
}

const updateAsset = async () => {
  const trimmedName = editAsset.value.name.trim()
  if (!trimmedName) return

  if (isSupabaseConfigured) {
    loading.value = true
    error.value = null
    const { data, error: updateError } = await supabase
      .from('assets')
      .update({
        name: trimmedName,
        category: editAsset.value.category || null,
        status: editAsset.value.status,
        location: editAsset.value.location || null,
        description: editAsset.value.description?.trim() || null,
      })
      .eq('id', editAsset.value.id)
      .select('id, name, category, status, location, description, updated_at')
      .single()

    if (updateError) {
      error.value = updateError.message
      loading.value = false
      return
    }

    if (data) {
      const updated = mapAssetRecord(data as AssetRecord)
      const index = assets.value.findIndex((asset) => asset.id === updated.id)
      if (index !== -1) {
        assets.value.splice(index, 1, updated)
      }
    }
    loading.value = false
  } else {
    const index = assets.value.findIndex((asset) => asset.id === editAsset.value.id)
    if (index !== -1) {
      assets.value.splice(index, 1, {
        id: editAsset.value.id,
        name: trimmedName,
        category: editAsset.value.category || 'Uncategorized',
        status: editAsset.value.status,
        location: editAsset.value.location || 'Unassigned',
        updatedAt: new Date().toISOString().slice(0, 10),
        description: editAsset.value.description?.trim(),
      })
    }
  }

  resetEditForm()
  isEditDialogOpen.value = false
}

onMounted(fetchAssets)
</script>

<template>
  <SidebarLayout>
    <div class="flex flex-col gap-6 pb-10">
      <Dialog v-model:open="isDialogOpen">
        <div class="flex flex-col gap-4 rounded-3xl border border-slate-800/80 bg-slate-900/60 p-8 shadow-lg shadow-slate-950/30">
          <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <p class="text-xs uppercase tracking-[0.2em] text-slate-300">Assets</p>
              <h1 class="mt-2 text-3xl font-semibold text-white">Inventory command center</h1>
              <p class="mt-2 text-sm text-slate-200">
                Track critical equipment, status, and last activity in one view.
              </p>
            </div>
            <DialogTrigger as-child>
              <Button class="hidden bg-amber-300 text-slate-950 hover:bg-amber-200 sm:inline-flex">
                New Asset
              </Button>
            </DialogTrigger>
          </div>

          <div class="hidden flex-col gap-3 sm:flex lg:flex-row lg:items-center lg:justify-between">
            <div class="flex flex-1 flex-col gap-3 sm:flex-row sm:items-end">
              <div class="flex-1 space-y-2">
                <Label for="asset-search">Search</Label>
                <Input
                  id="asset-search"
                  v-model="search"
                  class="sm:max-w-xs"
                  placeholder="Search by name, ID, or location"
                />
              </div>
              <div class="space-y-2">
                <Label for="asset-status">Status</Label>
                <Select v-model="statusFilter">
                  <SelectTrigger id="asset-status" class="sm:w-44">
                    <SelectValue placeholder="All statuses" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All statuses</SelectItem>
                    <SelectItem value="Operational">Operational</SelectItem>
                    <SelectItem value="Needs Service">Needs Service</SelectItem>
                    <SelectItem value="Offline">Offline</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <Button
                v-if="hasActiveFilters"
                variant="ghost"
                class="justify-start text-slate-200 hover:text-white"
                @click="clearFilters"
              >
                Clear filters
              </Button>
            </div>
            <div class="flex items-center gap-2 text-xs text-slate-300">
              <Badge v-if="!isSupabaseConfigured" variant="outline" class="border-slate-700/80 text-slate-200">
                Local mode
              </Badge>
              <span v-if="loading">Syncing...</span>
              <span v-else>{{ filteredAssets.length }} assets</span>
            </div>
          </div>

          <p v-if="error" class="text-sm text-rose-300">
            {{ error }}
          </p>
        </div>

        <div class="sticky top-4 z-20 -mx-6 rounded-2xl border border-slate-800/80 bg-slate-950/85 px-6 py-4 shadow-lg shadow-slate-950/50 backdrop-blur sm:hidden">
          <div class="grid gap-3">
            <div class="grid gap-2">
              <Label class="sr-only" for="asset-search-mobile">Search</Label>
              <Input
                id="asset-search-mobile"
                v-model="search"
                placeholder="Search assets"
              />
            </div>
            <div class="flex items-center gap-2">
              <div class="flex-1">
                <Label class="sr-only" for="asset-status-mobile">Status</Label>
                <Select v-model="statusFilter">
                  <SelectTrigger id="asset-status-mobile">
                    <SelectValue placeholder="All statuses" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All statuses</SelectItem>
                    <SelectItem value="Operational">Operational</SelectItem>
                    <SelectItem value="Needs Service">Needs Service</SelectItem>
                    <SelectItem value="Offline">Offline</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <DialogTrigger as-child>
                <Button class="bg-amber-300 text-slate-950 hover:bg-amber-200">
                  New
                </Button>
              </DialogTrigger>
            </div>
            <Button
              v-if="hasActiveFilters"
              variant="ghost"
              class="justify-start text-slate-200 hover:text-white"
              @click="clearFilters"
            >
              Clear filters
            </Button>
          </div>
        </div>

        <DialogContent class="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>Register an asset</DialogTitle>
            <DialogDescription>
              Add the core details now. You can fill in maintenance and ownership later.
            </DialogDescription>
          </DialogHeader>
          <div class="grid gap-4 py-2">
            <div class="grid gap-2">
              <Label for="asset-name">Asset name</Label>
              <Input id="asset-name" v-model="newAsset.name" placeholder="Forklift FL-12" />
            </div>
            <div class="grid gap-2">
              <Label for="asset-category">Category</Label>
              <Input id="asset-category" v-model="newAsset.category" placeholder="Material Handling" />
            </div>
            <div class="grid gap-2">
              <Label>Status</Label>
              <Select v-model="newAsset.status">
                <SelectTrigger>
                  <SelectValue placeholder="Select a status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Operational">Operational</SelectItem>
                  <SelectItem value="Needs Service">Needs Service</SelectItem>
                  <SelectItem value="Offline">Offline</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div class="grid gap-2">
              <Label for="asset-location">Location</Label>
              <Input id="asset-location" v-model="newAsset.location" placeholder="Dock 2" />
            </div>
            <div class="grid gap-2">
              <Label for="asset-notes">Notes</Label>
              <Textarea id="asset-notes" v-model="newAsset.description" placeholder="Add any quick notes" />
            </div>
          </div>
          <DialogFooter class="gap-2 sm:justify-end">
            <Button
              variant="outline"
              class="border-slate-600/80 bg-slate-900 text-slate-100 hover:bg-slate-800 hover:text-white"
              @click="isDialogOpen = false"
            >
              Cancel
            </Button>
            <Button class="bg-amber-300 text-slate-950 hover:bg-amber-200" @click="addAsset">
              Save asset
            </Button>
          </DialogFooter>
        </DialogContent>
        <div
          v-if="hasActiveFilters"
          class="flex flex-wrap items-center gap-2 rounded-2xl border border-slate-800/80 bg-slate-900/40 px-4 py-3 text-xs text-slate-200"
        >
          <Badge
            v-for="filter in activeFilters"
            :key="filter.label"
            variant="outline"
            class="border-slate-700/80 text-slate-200"
          >
            {{ filter.label }}: {{ filter.value }}
          </Badge>
          <Button variant="ghost" class="text-slate-200 hover:text-white" @click="clearFilters">
            Clear all
          </Button>
        </div>

        <div class="overflow-hidden rounded-3xl border border-slate-800/80 bg-slate-900/60">
          <div class="hidden grid-cols-5 gap-4 px-6 py-4 text-xs uppercase tracking-[0.2em] text-slate-300 sm:grid">
            <span>Asset</span>
            <span>Status</span>
            <span>Category</span>
            <span>Location</span>
            <span>Updated</span>
          </div>
          <div class="divide-y divide-slate-800/80">
            <div v-for="asset in filteredAssets" :key="asset.id" class="px-6 py-4 text-sm text-slate-100">
              <div class="space-y-3 sm:hidden">
                <div class="flex items-start justify-between gap-4">
                  <div>
                    <p class="text-base font-semibold text-white">{{ asset.name }}</p>
                    <p class="text-xs text-slate-300">{{ asset.id }}</p>
                  </div>
                  <Badge variant="outline" :class="statusBadgeClass(asset.status)">
                    {{ asset.status }}
                  </Badge>
                </div>
                <div class="flex items-center gap-2">
                  <Button
                    variant="outline"
                    class="border-slate-700/80 bg-slate-900/60 text-slate-100 hover:bg-slate-800/80 hover:text-white"
                    @click="startEdit(asset)"
                  >
                    Edit
                  </Button>
                </div>
                <dl class="space-y-2 text-sm text-slate-200">
                  <div class="flex items-center justify-between">
                    <dt class="text-xs uppercase tracking-[0.18em] text-slate-400">Category</dt>
                    <dd>{{ asset.category }}</dd>
                  </div>
                  <div class="flex items-center justify-between">
                    <dt class="text-xs uppercase tracking-[0.18em] text-slate-400">Location</dt>
                    <dd>{{ asset.location }}</dd>
                  </div>
                  <div class="flex items-center justify-between">
                    <dt class="text-xs uppercase tracking-[0.18em] text-slate-400">Updated</dt>
                    <dd>{{ asset.updatedAt }}</dd>
                  </div>
                </dl>
              </div>
              <div class="hidden grid-cols-5 gap-4 text-sm text-slate-200 sm:grid">
                <div class="space-y-1">
                  <p class="font-semibold text-white">{{ asset.name }}</p>
                  <p class="text-xs text-slate-300">{{ asset.id }}</p>
                  <Button
                    variant="outline"
                    size="sm"
                    class="mt-2 border-slate-700/80 bg-slate-900/60 text-slate-100 hover:bg-slate-800/80 hover:text-white"
                    @click="startEdit(asset)"
                  >
                    Edit
                  </Button>
                </div>
                <div class="flex items-center">
                  <Badge variant="outline" :class="statusBadgeClass(asset.status)">
                    {{ asset.status }}
                  </Badge>
                </div>
                <div class="text-slate-200">{{ asset.category }}</div>
                <div class="text-slate-200">{{ asset.location }}</div>
                <div class="text-slate-300">{{ asset.updatedAt }}</div>
              </div>
            </div>
            <div v-if="filteredAssets.length === 0" class="px-6 py-12 text-center text-sm text-slate-300">
              <div v-if="assets.length === 0" class="space-y-3">
                <p class="text-base font-semibold text-white">No assets yet.</p>
                <p class="text-sm text-slate-300">Create the first asset to start tracking inventory.</p>
                <DialogTrigger as-child>
                  <Button class="bg-amber-300 text-slate-950 hover:bg-amber-200">
                    Create your first asset
                  </Button>
                </DialogTrigger>
              </div>
              <div v-else class="space-y-3">
                <p class="text-base font-semibold text-white">No assets match these filters.</p>
                <p class="text-sm text-slate-300">Try adjusting your filters to see results.</p>
                <Button
                  v-if="hasActiveFilters"
                  variant="outline"
                  class="border-slate-700 text-slate-200 hover:bg-slate-800"
                  @click="clearFilters"
                >
                  Clear filters
                </Button>
              </div>
            </div>
          </div>
        </div>
      </Dialog>
      <Dialog v-model:open="isEditDialogOpen">
        <DialogContent class="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>Edit asset</DialogTitle>
            <DialogDescription>
              Update the core details to keep inventory accurate.
            </DialogDescription>
          </DialogHeader>
          <div class="grid gap-4 py-2">
            <div class="grid gap-2">
              <Label for="edit-asset-name">Asset name</Label>
              <Input id="edit-asset-name" v-model="editAsset.name" placeholder="Forklift FL-12" />
            </div>
            <div class="grid gap-2">
              <Label for="edit-asset-category">Category</Label>
              <Input id="edit-asset-category" v-model="editAsset.category" placeholder="Material Handling" />
            </div>
            <div class="grid gap-2">
              <Label>Status</Label>
              <Select v-model="editAsset.status">
                <SelectTrigger>
                  <SelectValue placeholder="Select a status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Operational">Operational</SelectItem>
                  <SelectItem value="Needs Service">Needs Service</SelectItem>
                  <SelectItem value="Offline">Offline</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div class="grid gap-2">
              <Label for="edit-asset-location">Location</Label>
              <Input id="edit-asset-location" v-model="editAsset.location" placeholder="Dock 2" />
            </div>
            <div class="grid gap-2">
              <Label for="edit-asset-notes">Notes</Label>
              <Textarea id="edit-asset-notes" v-model="editAsset.description" placeholder="Add any quick notes" />
            </div>
          </div>
          <DialogFooter class="gap-2 sm:justify-end">
            <Button
              variant="outline"
              class="border-slate-600/80 bg-slate-900 text-slate-100 hover:bg-slate-800 hover:text-white"
              @click="isEditDialogOpen = false"
            >
              Cancel
            </Button>
            <Button class="bg-amber-300 text-slate-950 hover:bg-amber-200" @click="updateAsset">
              Save changes
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  </SidebarLayout>
</template>
