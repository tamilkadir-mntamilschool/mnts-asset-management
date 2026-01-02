<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'
import { useSessionStore } from '@/stores/session'

type Asset = {
  id: string
  assetCode: string
  name: string
  category: string
  location: string
  updatedAt: string
  description?: string
  permanentOwnerId: string | null
  borrowerId: string | null
  loanStatus: 'Available' | 'On Loan'
}

type AssetRecord = {
  id: string
  asset_code: string
  permanent_owner_id: string
  name: string
  category: string | null
  location: string | null
  description: string | null
  updated_at: string
}

type ActiveLoanRecord = {
  asset_id: string
  borrower_id: string
  checked_out_at: string
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

const fallbackAssets: Asset[] = [
  {
    id: 'A-1023',
    assetCode: 'MNTS-ASSET-000123',
    name: 'Forklift FL-12',
    category: 'Material Handling',
    location: 'Dock 2',
    updatedAt: '2025-01-18',
    permanentOwnerId: null,
    borrowerId: null,
    loanStatus: 'Available',
  },
  {
    id: 'A-1041',
    assetCode: 'MNTS-ASSET-000124',
    name: 'CNC Router 7B',
    category: 'Fabrication',
    location: 'Plant 1',
    updatedAt: '2025-01-12',
    permanentOwnerId: null,
    borrowerId: null,
    loanStatus: 'Available',
  },
  {
    id: 'A-1078',
    assetCode: 'MNTS-ASSET-000125',
    name: 'Chiller Unit 4',
    category: 'Facilities',
    location: 'Rooftop',
    updatedAt: '2024-12-29',
    permanentOwnerId: null,
    borrowerId: null,
    loanStatus: 'Available',
  },
]

const sessionStore = useSessionStore()
const assets = ref<Asset[]>([])
const loading = ref(false)
const error = ref<string | null>(null)
const profileLookup = ref<Record<string, Profile>>({})

const search = ref('')
const ownershipFilter = ref<'all' | 'owned' | 'borrowed'>('all')
const isScanOpen = ref(false)
const scanError = ref<string | null>(null)
const isScanning = ref(false)
const videoRef = ref<HTMLVideoElement | null>(null)

const filteredAssets = computed(() => {
  const userId = sessionStore.user?.id ?? null
  return assets.value.filter((asset) => {
    const matchesSearch =
      asset.name.toLowerCase().includes(search.value.toLowerCase()) ||
      asset.id.toLowerCase().includes(search.value.toLowerCase()) ||
      asset.assetCode.toLowerCase().includes(search.value.toLowerCase()) ||
      asset.location.toLowerCase().includes(search.value.toLowerCase())
    const matchesOwnership =
      ownershipFilter.value === 'all' ||
      (ownershipFilter.value === 'owned' && userId && asset.permanentOwnerId === userId) ||
      (ownershipFilter.value === 'borrowed' && userId && asset.borrowerId === userId)
    return matchesSearch && matchesOwnership
  })
})

const activeFilters = computed(() => {
  const filters: { label: string; value: string }[] = []
  const trimmedSearch = search.value.trim()
  if (trimmedSearch) {
    filters.push({ label: 'Search', value: trimmedSearch })
  }
  if (ownershipFilter.value === 'owned') {
    filters.push({ label: 'Ownership', value: 'Owned by me' })
  }
  if (ownershipFilter.value === 'borrowed') {
    filters.push({ label: 'Ownership', value: 'Borrowed by me' })
  }
  return filters
})

const hasActiveFilters = computed(() => activeFilters.value.length > 0)
const hasUser = computed(() => Boolean(sessionStore.user?.id))
const canScan = computed(() => typeof window !== 'undefined' && 'BarcodeDetector' in window)

let scanStream: MediaStream | null = null
let scanAnimationFrame: number | null = null
let barcodeDetector: { detect: (source: ImageBitmapSource) => Promise<Array<{ rawValue: string }>> } | null = null

const mapAssetRecord = (
  record: AssetRecord,
  activeLoanLookup: Map<string, ActiveLoanRecord>,
): Asset => {
  const activeLoan = activeLoanLookup.get(record.id)
  return {
    id: record.id,
    assetCode: record.asset_code,
    name: record.name,
    category: record.category ?? 'Uncategorized',
    location: record.location ?? 'Unassigned',
    updatedAt: record.updated_at?.slice(0, 10) ?? '—',
    description: record.description ?? '',
    permanentOwnerId: record.permanent_owner_id,
    borrowerId: activeLoan?.borrower_id ?? null,
    loanStatus: activeLoan ? 'On Loan' : 'Available',
  }
}

const mapProfileRecord = (record: ProfileRecord): Profile => ({
  id: record.id,
  fullName: record.full_name,
  email: record.email,
})

const profileLabel = (profile: Profile | undefined) => {
  if (!profile) return null
  return profile.fullName || profile.email
}

const profileName = (userId: string | null | undefined) => {
  if (!userId) return '—'
  if (sessionStore.user?.id === userId) return 'You'
  const profile = profileLookup.value[userId]
  return profileLabel(profile) ?? userId
}

const fetchAssets = async () => {
  if (!isSupabaseConfigured) {
    assets.value = fallbackAssets
    return
  }

  loading.value = true
  error.value = null

  const { data: assetData, error: fetchError } = await supabase
    .from('assets')
    .select('id, asset_code, permanent_owner_id, name, category, location, description, updated_at')
    .order('updated_at', { ascending: false })

  if (fetchError) {
    error.value = fetchError.message
    assets.value = []
  } else {
    const { data: loanData, error: loanError } = await supabase
      .from('asset_loans')
      .select('asset_id, borrower_id, checked_out_at')
      .is('checked_in_at', null)

    if (loanError) {
      error.value = loanError.message
    }

    const activeLoanLookup = new Map<string, ActiveLoanRecord>()
    if (loanData) {
      ;(loanData as ActiveLoanRecord[]).forEach((loan) => {
        activeLoanLookup.set(loan.asset_id, loan)
      })
    }

    const profileIds = new Set<string>()
    ;(assetData as AssetRecord[]).forEach((record) => {
      if (record.permanent_owner_id) {
        profileIds.add(record.permanent_owner_id)
      }
    })
    if (loanData) {
      ;(loanData as ActiveLoanRecord[]).forEach((loan) => {
        if (loan.borrower_id) {
          profileIds.add(loan.borrower_id)
        }
      })
    }

    if (profileIds.size > 0) {
      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('id, full_name, email')
        .in('id', Array.from(profileIds))

      if (profileError) {
        error.value = profileError.message
      } else if (profileData) {
        const lookup: Record<string, Profile> = {}
        ;(profileData as ProfileRecord[]).forEach((profile) => {
          lookup[profile.id] = mapProfileRecord(profile)
        })
        profileLookup.value = lookup
      }
    } else {
      profileLookup.value = {}
    }

    assets.value = (assetData as AssetRecord[]).map((record) => mapAssetRecord(record, activeLoanLookup))
  }

  loading.value = false
}

const loanBadgeClass = (status: Asset['loanStatus']) => {
  if (status === 'On Loan') return 'border-amber-400/50 bg-amber-400/15 text-amber-100'
  return 'border-slate-500/60 bg-slate-400/10 text-slate-200'
}

const extractSearchTerm = (rawValue: string) => {
  const trimmed = rawValue.trim()
  try {
    const parsed = new URL(trimmed)
    const codeMatch = parsed.pathname.match(/\/assets\/code\/([^/]+)/)
    if (codeMatch) return decodeURIComponent(codeMatch[1])
    const idMatch = parsed.pathname.match(/\/assets\/([^/]+)/)
    if (idMatch) return decodeURIComponent(idMatch[1])
  } catch {
    // Not a URL, fall back to raw text.
  }
  return trimmed
}

const stopScanner = () => {
  isScanning.value = false
  if (scanAnimationFrame !== null) {
    cancelAnimationFrame(scanAnimationFrame)
    scanAnimationFrame = null
  }
  if (videoRef.value) {
    videoRef.value.pause()
    videoRef.value.srcObject = null
  }
  if (scanStream) {
    scanStream.getTracks().forEach((track) => track.stop())
    scanStream = null
  }
}

const scanLoop = async () => {
  if (!isScanning.value || !videoRef.value || !barcodeDetector) return
  try {
    const results = await barcodeDetector.detect(videoRef.value)
    if (results.length > 0) {
      search.value = extractSearchTerm(results[0].rawValue)
      isScanOpen.value = false
      return
    }
  } catch (err) {
    scanError.value = err instanceof Error ? err.message : 'Unable to read QR code.'
    isScanOpen.value = false
    return
  }
  scanAnimationFrame = requestAnimationFrame(scanLoop)
}

const startScanner = async () => {
  scanError.value = null
  if (!('mediaDevices' in navigator) || !navigator.mediaDevices.getUserMedia) {
    scanError.value = 'Camera access is not available in this browser.'
    return
  }
  if (!canScan.value) {
    scanError.value = 'QR scanning is not supported in this browser.'
    return
  }
  try {
    scanStream = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: { ideal: 'environment' } },
      audio: false,
    })
    if (videoRef.value) {
      videoRef.value.srcObject = scanStream
      await videoRef.value.play()
    }
    barcodeDetector = new (window as unknown as { BarcodeDetector: new (options: { formats: string[] }) => any })
      .BarcodeDetector({
        formats: ['qr_code'],
      })
    isScanning.value = true
    scanLoop()
  } catch (err) {
    scanError.value = err instanceof Error ? err.message : 'Unable to access the camera.'
    stopScanner()
  }
}

const clearFilters = () => {
  search.value = ''
  ownershipFilter.value = 'all'
}

onMounted(fetchAssets)

watch(isScanOpen, (isOpen) => {
  if (isOpen) {
    void startScanner()
  } else {
    stopScanner()
  }
})

onBeforeUnmount(() => {
  stopScanner()
})
</script>

<template>
  <div class="mx-auto flex w-full max-w-6xl flex-col gap-6 px-6 py-10">
    <div class="flex flex-col gap-6 pb-10">
      <Dialog v-model:open="isScanOpen">
        <DialogContent class="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>Scan asset QR code</DialogTitle>
            <DialogDescription>
              Point your camera at an asset QR code to filter the list.
            </DialogDescription>
          </DialogHeader>
          <div class="space-y-4">
            <div class="overflow-hidden rounded-2xl border border-slate-800/80 bg-slate-950/70">
              <video ref="videoRef" class="h-72 w-full object-cover" playsinline muted></video>
            </div>
            <p v-if="!canScan" class="text-xs text-slate-400">
              QR scanning is not supported in this browser. Use the search box instead.
            </p>
            <p v-else-if="scanError" class="text-xs text-rose-300">
              {{ scanError }}
            </p>
            <p v-else class="text-xs text-slate-400">Point at a QR code to scan.</p>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              class="border-slate-600/80 bg-slate-900 text-slate-100 hover:bg-slate-800 hover:text-white"
              @click="isScanOpen = false"
            >
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
      <div>
        <div class="flex flex-col gap-4 rounded-3xl border border-slate-800/80 bg-slate-900/60 p-8 shadow-lg shadow-slate-950/30">
          <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <p class="text-xs uppercase tracking-[0.2em] text-slate-300">Assets</p>
              <h1 class="mt-2 text-3xl font-semibold text-white">Dashboard</h1>
            </div>
            <div class="hidden items-center gap-2 sm:flex">
              <Button class="bg-amber-300 text-slate-950 hover:bg-amber-200" as-child>
                <RouterLink to="/assets/new">New Asset</RouterLink>
              </Button>
            </div>
          </div>

          <div class="hidden flex-col gap-3 sm:flex lg:flex-row lg:items-center lg:justify-between">
            <div class="flex flex-1 flex-col gap-3 sm:flex-row sm:items-end">
              <div class="flex-1 space-y-2">
                <Label for="asset-search">Search</Label>
                <div class="flex flex-wrap gap-2 sm:flex-nowrap sm:items-center">
                  <Input
                    id="asset-search"
                    v-model="search"
                    class="sm:max-w-xs"
                    placeholder="Search by name, code, or location"
                  />
                  <Button
                    variant="outline"
                    class="border-slate-700/80 bg-slate-900 text-slate-100 hover:bg-slate-800 hover:text-white"
                    @click="isScanOpen = true"
                  >
                    Scan QR
                  </Button>
                </div>
              </div>
              <div v-if="hasUser" class="space-y-2">
                <Label>Ownership</Label>
                <div class="flex flex-wrap gap-2">
                  <Button
                    size="sm"
                    variant="outline"
                    :class="
                      ownershipFilter === 'all'
                        ? 'border-amber-300 bg-amber-300 text-slate-950 hover:bg-amber-200'
                        : 'border-slate-700/80 bg-slate-900/60 text-slate-100 hover:bg-slate-800/80 hover:text-white'
                    "
                    @click="ownershipFilter = 'all'"
                  >
                    All assets
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    :class="
                      ownershipFilter === 'owned'
                        ? 'border-amber-300 bg-amber-300 text-slate-950 hover:bg-amber-200'
                        : 'border-slate-700/80 bg-slate-900/60 text-slate-100 hover:bg-slate-800/80 hover:text-white'
                    "
                    @click="ownershipFilter = 'owned'"
                  >
                    Owned by me
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    :class="
                      ownershipFilter === 'borrowed'
                        ? 'border-amber-300 bg-amber-300 text-slate-950 hover:bg-amber-200'
                        : 'border-slate-700/80 bg-slate-900/60 text-slate-100 hover:bg-slate-800/80 hover:text-white'
                    "
                    @click="ownershipFilter = 'borrowed'"
                  >
                    Borrowed by me
                  </Button>
                </div>
              </div>
            </div>
          </div>
          <div class="flex flex-wrap items-center justify-end gap-3 text-xs text-slate-300">
            <Badge v-if="!isSupabaseConfigured" variant="outline" class="border-slate-700/80 text-slate-200">
              Local demo mode
            </Badge>
            <span v-if="loading">Syncing...</span>
            <span v-else>{{ filteredAssets.length }} assets</span>
            <Button
              v-if="hasActiveFilters"
              size="sm"
              variant="outline"
              class="border-slate-700/80 bg-slate-900/60 text-slate-100 hover:bg-slate-800/80 hover:text-white"
              @click="clearFilters"
            >
              Reset filters
            </Button>
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
              <Button
                variant="outline"
                class="border-slate-700/80 bg-slate-900/60 text-slate-100 hover:bg-slate-800/80 hover:text-white"
                @click="isScanOpen = true"
              >
                Scan QR Code
              </Button>
              <Button class="bg-amber-300 text-slate-950 hover:bg-amber-200" as-child>
                <RouterLink to="/assets/new">New Asset</RouterLink>
              </Button>
            </div>
            <div v-if="hasUser" class="flex flex-wrap gap-2">
              <Button
                size="sm"
                variant="outline"
                :class="
                  ownershipFilter === 'all'
                    ? 'border-amber-300 bg-amber-300 text-slate-950 hover:bg-amber-200'
                    : 'border-slate-700/80 bg-slate-900/60 text-slate-100 hover:bg-slate-800/80 hover:text-white'
                "
                @click="ownershipFilter = 'all'"
              >
                All assets
              </Button>
              <Button
                size="sm"
                variant="outline"
                :class="
                  ownershipFilter === 'owned'
                    ? 'border-amber-300 bg-amber-300 text-slate-950 hover:bg-amber-200'
                    : 'border-slate-700/80 bg-slate-900/60 text-slate-100 hover:bg-slate-800/80 hover:text-white'
                "
                @click="ownershipFilter = 'owned'"
              >
                Owned by me
              </Button>
              <Button
                size="sm"
                variant="outline"
                :class="
                  ownershipFilter === 'borrowed'
                    ? 'border-amber-300 bg-amber-300 text-slate-950 hover:bg-amber-200'
                    : 'border-slate-700/80 bg-slate-900/60 text-slate-100 hover:bg-slate-800/80 hover:text-white'
                "
                @click="ownershipFilter = 'borrowed'"
              >
                Borrowed by me
              </Button>
            </div>
          </div>
        </div>
        <div class="mt-3 flex flex-wrap items-center justify-end gap-3 text-xs text-slate-300 sm:hidden">
          <Badge v-if="!isSupabaseConfigured" variant="outline" class="border-slate-700/80 text-slate-200">
            Local demo mode
          </Badge>
          <span v-if="loading">Syncing...</span>
          <span v-else>{{ filteredAssets.length }} assets</span>
          <Button
            v-if="hasActiveFilters"
            size="sm"
            variant="outline"
            class="border-slate-700/80 bg-slate-900/60 text-slate-100 hover:bg-slate-800/80 hover:text-white"
            @click="clearFilters"
          >
            Reset filters
          </Button>
        </div>

        <div class="mt-6 overflow-hidden rounded-3xl border border-slate-800/80 bg-slate-900/60">
          <div class="hidden grid-cols-8 gap-4 px-6 py-4 text-xs uppercase tracking-[0.2em] text-slate-300 sm:grid">
            <span>Asset</span>
            <span>Owner</span>
            <span>Loan Status</span>
            <span>Borrower</span>
            <span>Category</span>
            <span>Location</span>
            <span>Updated</span>
            <span class="text-right">&nbsp;</span>
          </div>
          <div class="divide-y divide-slate-800/80">
            <div v-for="asset in filteredAssets" :key="asset.id" class="px-6 py-4 text-sm text-slate-100">
              <div class="space-y-3 sm:hidden">
                <div class="flex items-start justify-between gap-4">
                  <div>
                    <p class="text-base font-semibold text-white">{{ asset.name }}</p>
                    <p class="text-xs text-slate-300">{{ asset.assetCode }}</p>
                  </div>
                  <Badge variant="outline" :class="loanBadgeClass(asset.loanStatus)">
                    {{ asset.loanStatus }}
                  </Badge>
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
                    <dt class="text-xs uppercase tracking-[0.18em] text-slate-400">Owner</dt>
                    <dd>{{ profileName(asset.permanentOwnerId) }}</dd>
                  </div>
                  <div class="flex items-center justify-between">
                    <dt class="text-xs uppercase tracking-[0.18em] text-slate-400">Loan</dt>
                    <dd>
                      <Badge variant="outline" :class="loanBadgeClass(asset.loanStatus)">
                        {{ asset.loanStatus }}
                      </Badge>
                    </dd>
                  </div>
                  <div class="flex items-center justify-between">
                    <dt class="text-xs uppercase tracking-[0.18em] text-slate-400">Borrower</dt>
                    <dd>{{ asset.borrowerId ? profileName(asset.borrowerId) : '—' }}</dd>
                  </div>
                  <div class="flex items-center justify-between">
                    <dt class="text-xs uppercase tracking-[0.18em] text-slate-400">Updated</dt>
                    <dd>{{ asset.updatedAt }}</dd>
                  </div>
                </dl>
                <div class="flex justify-end">
                  <Button
                    v-if="isSupabaseConfigured"
                    as-child
                    variant="outline"
                    class="border-slate-700/80 bg-slate-900/60 text-slate-100 hover:bg-slate-800/80 hover:text-white"
                  >
                    <RouterLink :to="`/assets/${asset.id}`">View</RouterLink>
                  </Button>
                </div>
              </div>
              <div class="hidden grid-cols-8 gap-4 text-sm text-slate-200 sm:grid">
                <div class="space-y-1">
                  <RouterLink
                    v-if="isSupabaseConfigured"
                    :to="`/assets/${asset.id}`"
                    class="font-semibold text-white transition hover:text-amber-200"
                  >
                    {{ asset.name }}
                  </RouterLink>
                  <p v-else class="font-semibold text-white">{{ asset.name }}</p>
                  <p class="text-xs text-slate-300">{{ asset.assetCode }}</p>
                </div>
                <div class="text-slate-200">{{ profileName(asset.permanentOwnerId) }}</div>
                <div class="flex items-center">
                  <Badge variant="outline" :class="loanBadgeClass(asset.loanStatus)">
                    {{ asset.loanStatus }}
                  </Badge>
                </div>
                <div class="text-slate-200">{{ asset.borrowerId ? profileName(asset.borrowerId) : '—' }}</div>
                <div class="text-slate-200">{{ asset.category }}</div>
                <div class="text-slate-200">{{ asset.location }}</div>
                <div class="text-slate-300">{{ asset.updatedAt }}</div>
                <div class="flex justify-end">
                  <Button
                    v-if="isSupabaseConfigured"
                    as-child
                    variant="outline"
                    size="sm"
                    class="border-slate-700/80 bg-slate-900/60 text-slate-100 hover:bg-slate-800/80 hover:text-white"
                  >
                    <RouterLink :to="`/assets/${asset.id}`">View</RouterLink>
                  </Button>
                </div>
              </div>
            </div>
            <div v-if="filteredAssets.length === 0" class="px-6 py-12 text-center text-sm text-slate-300">
              <div v-if="assets.length === 0" class="space-y-3">
                <p class="text-base font-semibold text-white">Your inventory is empty.</p>
                <p class="text-sm text-slate-300">Add your first asset to start tracking inventory.</p>
                <Button class="bg-amber-300 text-slate-950 hover:bg-amber-200" as-child>
                  <RouterLink to="/assets/new">Add your first asset</RouterLink>
                </Button>
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
                  Reset filters
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
