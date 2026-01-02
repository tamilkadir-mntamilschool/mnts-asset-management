<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import QRCode from 'qrcode'
import { Button } from '@/components/ui/button'
import { isSupabaseConfigured, supabase } from '@/lib/supabase'

type AssetRecord = {
  id: string
  asset_code: string
  name: string
  category: string | null
  location: string | null
}

type Asset = {
  id: string
  assetCode: string
  name: string
  category: string
  location: string
}

const route = useRoute()
const asset = ref<Asset | null>(null)
const qrDataUrl = ref<string | null>(null)
const error = ref<string | null>(null)
const assetIdParam = computed(() => route.params.id as string | undefined)

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
})

const fetchAsset = async () => {
  if (!isSupabaseConfigured) {
    error.value = 'Supabase is not configured.'
    return
  }

  const { data, error: fetchError } = await supabase
    .from('assets')
    .select('id, asset_code, name, category, location')
    .eq('id', assetIdParam.value)
    .single()

  if (fetchError || !data) {
    error.value = fetchError?.message ?? 'Asset not found.'
  } else {
    asset.value = mapAssetRecord(data as AssetRecord)
  }
}

const generateQr = async () => {
  if (!asset.value) return
  try {
    qrDataUrl.value = await QRCode.toDataURL(assetUrl.value, { width: 420, margin: 2 })
  } catch (qrError) {
    console.error(qrError)
    qrDataUrl.value = null
  }
}

const printPage = () => {
  window.print()
}

onMounted(async () => {
  await fetchAsset()
  await generateQr()
})
</script>

<template>
  <div class="min-h-screen bg-slate-950 px-6 py-10 text-slate-100">
    <div class="mx-auto flex w-full max-w-3xl flex-col gap-6 print-text">
      <div class="flex flex-wrap items-center justify-between gap-4">
        <div>
          <p class="text-xs uppercase tracking-[0.2em] text-slate-300">Print QR code</p>
          <h1 class="mt-2 text-3xl font-semibold text-white">{{ asset?.name ?? 'Asset' }}</h1>
          <p class="mt-2 text-sm text-slate-300">MNTS Asset Management QR code for quick scanning.</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <Button
            v-if="asset"
            as-child
            variant="outline"
            class="print-hide border-slate-700/80 bg-slate-900 text-slate-100 hover:bg-slate-800 hover:text-white"
          >
            <RouterLink :to="`/assets/${asset.id}`">Back to asset</RouterLink>
          </Button>
          <Button class="print-hide bg-amber-300 text-slate-950 hover:bg-amber-200" @click="printPage">Print</Button>
        </div>
      </div>

      <div v-if="error" class="rounded-2xl border border-slate-800/80 bg-slate-900/60 p-6 text-rose-300 print-card">
        {{ error }}
      </div>

      <div v-if="asset" class="rounded-3xl border border-slate-800/80 bg-slate-900/60 p-8 print-card">
        <div class="flex flex-col items-center gap-6 text-center">
          <img v-if="qrDataUrl" :src="qrDataUrl" class="h-80 w-80" alt="Asset QR code" />
          <div class="space-y-2">
            <p class="text-lg font-semibold text-white">{{ asset.assetCode }}</p>
            <p class="text-sm text-slate-300">{{ asset.category }} • {{ asset.location }}</p>
            <p class="text-xs text-slate-400">{{ assetUrl }}</p>
          </div>
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

  .print-text {
    color: #000000;
  }
}
</style>
