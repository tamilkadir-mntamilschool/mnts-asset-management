<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useSessionStore } from '@/stores/session'

const sessionStore = useSessionStore()
const router = useRouter()
const isSettingsOpen = ref(false)
const isMenuOpen = ref(false)
const isMobileNavOpen = ref(false)
const settingsName = ref('')
const menuRef = ref<HTMLElement | null>(null)

const fallbackName = computed(() => {
  const metadataName = sessionStore.user?.user_metadata?.full_name as string | undefined
  return metadataName || sessionStore.user?.email || 'Ops Team'
})

const displayName = computed(() => fallbackName.value)

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
    isMobileNavOpen.value = false
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
      <header class="border-b border-slate-800/70 bg-slate-950/70 backdrop-blur">
        <div class="mx-auto flex w-full max-w-6xl items-center justify-between px-6 py-4">
          <div class="flex items-center gap-3">
            <button
              class="rounded-xl border border-slate-800/80 bg-slate-900/80 p-2 text-slate-200 transition hover:bg-slate-800 md:hidden"
              type="button"
              aria-label="Open menu"
              @click="isMobileNavOpen = true"
            >
              <svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                <path d="M4 6h16M4 12h16M4 18h16" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
              </svg>
            </button>
            <span class="inline-flex h-9 w-9 items-center justify-center rounded-xl bg-amber-300 text-slate-950">
              M
            </span>
            <div>
              <p class="text-sm font-semibold tracking-wide">MNTS</p>
              <p class="text-xs text-slate-300">Asset Command</p>
            </div>
          </div>
          <nav class="hidden items-center gap-6 text-sm text-slate-200 md:flex">
            <RouterLink class="transition hover:text-white" active-class="text-white" to="/assets">
              Assets
            </RouterLink>
          </nav>
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
                    Settings
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
      <div
        v-if="isMobileNavOpen"
        class="fixed inset-0 z-40 bg-slate-950/60 backdrop-blur-sm md:hidden"
        @click="isMobileNavOpen = false"
      ></div>
      <aside
        class="fixed bottom-0 left-0 top-0 z-50 w-72 -translate-x-full border-r border-slate-800/80 bg-slate-950/95 px-6 py-6 text-slate-100 transition-transform md:hidden"
        :class="isMobileNavOpen ? 'translate-x-0' : '-translate-x-full'"
        aria-label="Mobile navigation"
      >
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <span class="inline-flex h-9 w-9 items-center justify-center rounded-xl bg-amber-300 text-slate-950">
              M
            </span>
            <div>
              <p class="text-sm font-semibold tracking-wide">MNTS</p>
              <p class="text-xs text-slate-300">Asset Command</p>
            </div>
          </div>
          <button
            class="rounded-xl border border-slate-800/80 bg-slate-900/80 p-2 text-slate-200 transition hover:bg-slate-800"
            type="button"
            aria-label="Close menu"
            @click="isMobileNavOpen = false"
          >
            <svg class="h-5 w-5" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <path d="M6 6l12 12M6 18L18 6" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
            </svg>
          </button>
        </div>
        <nav class="mt-8 flex flex-col gap-2 text-sm text-slate-200">
          <RouterLink
            class="rounded-lg px-3 py-2 transition hover:bg-slate-800/70 hover:text-white"
            active-class="bg-slate-800/70 text-white"
            to="/assets"
            @click="isMobileNavOpen = false"
          >
            Assets
          </RouterLink>
        </nav>
        <div class="mt-8 border-t border-slate-800/80 pt-4">
          <DialogTrigger v-if="sessionStore.user" as-child>
            <button
              class="w-full rounded-lg px-3 py-2 text-left text-sm text-slate-200 transition hover:bg-slate-800/70 hover:text-white"
              type="button"
              @click="isMobileNavOpen = false"
            >
              Profile settings
            </button>
          </DialogTrigger>
          <RouterLink
            v-else
            class="block rounded-lg px-3 py-2 text-left text-sm text-slate-200 transition hover:bg-slate-800/70 hover:text-white"
            to="/auth"
            @click="isMobileNavOpen = false"
          >
            Sign in
          </RouterLink>
        </div>
      </aside>
    </div>

    <DialogContent class="sm:max-w-lg">
      <DialogHeader>
        <DialogTitle>Account settings</DialogTitle>
        <DialogDescription>
          Update the display name shown in the header.
        </DialogDescription>
      </DialogHeader>
      <div class="grid gap-4 py-2">
        <div class="grid gap-2">
          <Label for="settings-name">Name</Label>
          <Input id="settings-name" v-model="settingsName" placeholder="Your name" />
        </div>
        <div class="rounded-xl border border-slate-800/80 bg-slate-950/70 p-4">
          <p class="text-xs uppercase tracking-[0.2em] text-slate-400">Preview</p>
          <div class="mt-2 flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-full bg-slate-800 text-xs font-semibold">
              {{ initials }}
            </div>
            <div>
              <p class="text-sm font-semibold text-white">{{ settingsName || displayName }}</p>
            </div>
          </div>
        </div>
      </div>
      <DialogFooter class="gap-2 sm:justify-end">
        <Button
          variant="outline"
          class="border-slate-700 text-slate-200 hover:bg-slate-800"
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
