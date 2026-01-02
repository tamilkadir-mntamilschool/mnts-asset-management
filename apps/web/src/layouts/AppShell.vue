<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useSessionStore } from '@/stores/session'

const sessionStore = useSessionStore()
const router = useRouter()
const route = useRoute()
const isSettingsOpen = ref(false)
const isMenuOpen = ref(false)
const settingsName = ref('')
const menuRef = ref<HTMLElement | null>(null)

const fallbackName = computed(() => {
  const metadataName = sessionStore.user?.user_metadata?.full_name as string | undefined
  return metadataName || sessionStore.user?.email || 'Ops Team'
})

const displayName = computed(() => fallbackName.value)
const isAuthRoute = computed(() => route.name === 'auth' || route.path === '/' || route.path === '/auth')

const initials = computed(() => {
  const name = displayName.value.trim()
  if (!name) return 'U'
  const parts = name.split(/\s+/).slice(0, 2)
  return parts.map((part) => part[0]?.toUpperCase() ?? '').join('') || 'U'
})

const hydrateSettings = () => {
  settingsName.value = displayName.value
}

const handleSaveSettings = async () => {
  await sessionStore.updateProfile({
    full_name: settingsName.value.trim() || undefined,
  })
  if (!sessionStore.error) {
    isSettingsOpen.value = false
  }
}

const handleSignOut = async () => {
  await sessionStore.signOut()
  if (!sessionStore.error) {
    isMenuOpen.value = false
    await router.push('/auth')
  }
}

const handleDocumentClick = (event: MouseEvent) => {
  if (!isMenuOpen.value) return
  const target = event.target as Node | null
  if (menuRef.value && target && !menuRef.value.contains(target)) {
    isMenuOpen.value = false
  }
}

const handleDocumentKey = (event: KeyboardEvent) => {
  if (event.key === 'Escape') {
    isMenuOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleDocumentClick)
  document.addEventListener('keydown', handleDocumentKey)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleDocumentClick)
  document.removeEventListener('keydown', handleDocumentKey)
})

watch(isSettingsOpen, (isOpen) => {
  if (isOpen) {
    hydrateSettings()
  }
})
</script>

<template>
  <Dialog v-model:open="isSettingsOpen">
    <div class="app-background min-h-screen text-slate-100">
      <header v-if="!isAuthRoute" class="border-b border-slate-800/70 bg-slate-950/70 backdrop-blur">
        <div class="mx-auto flex w-full max-w-6xl items-center justify-between px-6 py-4">
          <div class="flex items-center gap-3">
            <RouterLink to="/assets" class="flex items-center gap-3 transition hover:text-white">
              <span class="inline-flex h-9 w-9 items-center justify-center rounded-xl bg-white">
                <img src="@/assets/mnts-logo.png" alt="MNTS logo" class="h-9 w-9 object-contain" />
              </span>
              <span class="text-sm font-semibold tracking-wide">MNTS Asset Management</span>
            </RouterLink>
          </div>
          <div class="flex items-center gap-3">
            <span v-if="sessionStore.loading" class="hidden text-xs text-slate-400 sm:inline">
              Syncing...
            </span>
            <span v-else-if="sessionStore.status === 'pending_confirmation'" class="hidden text-xs text-amber-200 sm:inline">
              Check your email
            </span>
            <span v-if="sessionStore.user" class="hidden text-xs text-slate-300 sm:inline">{{ displayName }}</span>
            <RouterLink
              v-if="!sessionStore.user"
              class="text-xs text-slate-200 transition hover:text-white"
              to="/auth"
            >
              Sign in
            </RouterLink>
            <div v-else ref="menuRef" class="relative">
              <button
                class="flex h-9 w-9 items-center justify-center rounded-full bg-slate-800/80 text-xs font-semibold transition hover:bg-slate-700"
                type="button"
                @click="isMenuOpen = !isMenuOpen"
              >
                {{ initials }}
              </button>
              <div
                v-if="isMenuOpen"
                class="absolute right-0 mt-2 w-48 rounded-xl border border-slate-800/80 bg-slate-950/95 p-2 text-sm shadow-lg"
              >
                <DialogTrigger as-child>
                  <button
                    class="w-full rounded-lg px-3 py-2 text-left text-slate-100 transition hover:bg-slate-800/70"
                    type="button"
                    @click="isMenuOpen = false"
                  >
                    Profile settings
                  </button>
                </DialogTrigger>
                <button
                  class="mt-1 w-full rounded-lg px-3 py-2 text-left text-rose-200 transition hover:bg-slate-800/70"
                  type="button"
                  @click="handleSignOut"
                >
                  Sign out
                </button>
              </div>
            </div>
          </div>
        </div>
      </header>
      <main class="pb-0">
        <slot />
      </main>
    </div>

    <DialogContent class="border-slate-800/80 bg-slate-950/95 text-slate-100 shadow-xl shadow-slate-950/50 sm:max-w-lg">
      <DialogHeader>
        <DialogTitle>Profile settings</DialogTitle>
        <DialogDescription>
          Update the display name shown in the header.
        </DialogDescription>
      </DialogHeader>
      <div class="grid gap-4 py-2">
        <div class="grid gap-2">
          <Label for="settings-name">Name</Label>
          <Input id="settings-name" v-model="settingsName" placeholder="Your name" />
        </div>
      </div>
      <DialogFooter class="gap-2 sm:justify-end">
        <Button
          variant="outline"
          class="border-slate-700/80 bg-slate-900 text-slate-100 hover:bg-slate-800 hover:text-white"
          @click="isSettingsOpen = false"
        >
          Cancel
        </Button>
        <Button
          class="bg-amber-300 text-slate-950 hover:bg-amber-200"
          :disabled="sessionStore.loading"
          @click="handleSaveSettings"
        >
          Save changes
        </Button>
      </DialogFooter>
    </DialogContent>
  </Dialog>
</template>
