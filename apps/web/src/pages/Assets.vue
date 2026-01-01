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
const newAsset = ref({
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

const statusBadgeVariant = (status: AssetStatus) => {
  if (status === 'Operational') return 'secondary'
  if (status === 'Needs Service') return 'outline'
  return 'destructive'
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

onMounted(fetchAssets)
</script>

<template>
  <SidebarLayout>
    <div class="flex flex-col gap-6">
      <div class="flex flex-col gap-4 rounded-3xl border border-slate-800 bg-slate-900/60 p-8">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p class="text-xs uppercase tracking-[0.2em] text-slate-400">Assets</p>
            <h1 class="mt-2 text-3xl font-semibold">Inventory command center</h1>
            <p class="mt-2 text-sm text-slate-300">
              Track critical equipment, status, and last activity in one view.
            </p>
          </div>
          <Dialog v-model:open="isDialogOpen">
            <DialogTrigger as-child>
              <Button class="bg-slate-100 text-slate-950 hover:bg-white">
                New Asset
              </Button>
            </DialogTrigger>
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
                <Button variant="outline" class="border-slate-700 text-slate-200 hover:bg-slate-800" @click="isDialogOpen = false">
                  Cancel
                </Button>
                <Button class="bg-slate-100 text-slate-950 hover:bg-white" @click="addAsset">
                  Save asset
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>

        <div class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <div class="flex flex-1 flex-col gap-3 sm:flex-row sm:items-center">
            <Input v-model="search" class="sm:max-w-xs" placeholder="Search by name, ID, or location" />
            <Select v-model="statusFilter">
              <SelectTrigger class="sm:w-44">
                <SelectValue placeholder="All statuses" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All statuses</SelectItem>
                <SelectItem value="Operational">Operational</SelectItem>
                <SelectItem value="Needs Service">Needs Service</SelectItem>
                <SelectItem value="Offline">Offline</SelectItem>
              </SelectContent>
            </Select>
            <Button
              v-if="search || statusFilter !== 'all'"
              variant="ghost"
              class="justify-start text-slate-300 hover:text-slate-100"
              @click="clearFilters"
            >
              Clear filters
            </Button>
          </div>
          <div class="flex items-center gap-2 text-xs text-slate-400">
            <Badge v-if="!isSupabaseConfigured" variant="outline">Local mode</Badge>
            <span v-if="loading">Syncing...</span>
            <span v-else>{{ filteredAssets.length }} assets</span>
          </div>
        </div>

        <p v-if="error" class="text-sm text-rose-300">
          {{ error }}
        </p>
      </div>

      <div class="overflow-hidden rounded-3xl border border-slate-800 bg-slate-900/60">
        <div class="grid grid-cols-1 gap-4 px-6 py-4 text-xs uppercase tracking-[0.2em] text-slate-400 sm:grid-cols-5">
          <span>Asset</span>
          <span>Status</span>
          <span>Category</span>
          <span>Location</span>
          <span>Updated</span>
        </div>
        <div class="divide-y divide-slate-800/80">
          <div
            v-for="asset in filteredAssets"
            :key="asset.id"
            class="grid grid-cols-1 gap-4 px-6 py-4 text-sm text-slate-200 sm:grid-cols-5"
          >
            <div class="space-y-1">
              <p class="font-semibold">{{ asset.name }}</p>
              <p class="text-xs text-slate-400">{{ asset.id }}</p>
            </div>
            <div class="flex items-center">
              <Badge :variant="statusBadgeVariant(asset.status)">{{ asset.status }}</Badge>
            </div>
            <div class="text-slate-300">{{ asset.category }}</div>
            <div class="text-slate-300">{{ asset.location }}</div>
            <div class="text-slate-400">{{ asset.updatedAt }}</div>
          </div>
          <div v-if="filteredAssets.length === 0" class="px-6 py-10 text-center text-sm text-slate-400">
            No assets match these filters yet.
          </div>
        </div>
      </div>
    </div>
  </SidebarLayout>
</template>
