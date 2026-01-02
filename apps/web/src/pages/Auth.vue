<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { Button } from '@/components/ui/button'
import { useSessionStore } from '@/stores/session'

const sessionStore = useSessionStore()
const oauthError = ref<string | null>(null)

const handleGoogleSignIn = async () => {
  await sessionStore.signInWithGoogle()
}

onMounted(() => {
  const hashParams = new URLSearchParams(window.location.hash.replace(/^#/, ''))
  const searchParams = new URLSearchParams(window.location.search.replace(/^\?/, ''))
  const errorDescription = hashParams.get('error_description') || searchParams.get('error_description')
  const error = hashParams.get('error') || searchParams.get('error')
  if (error || errorDescription) {
    oauthError.value = 'Access denied. This Google account is not authorized.'
  }
})
</script>

<template>
  <section class="mx-auto w-full max-w-md px-6 py-16">
    <div class="flex flex-col items-center rounded-3xl border border-slate-800/80 bg-slate-900/60 p-8 text-center shadow-xl shadow-slate-950/40">
      <div class="flex flex-col items-center gap-3">
        <span class="inline-flex h-24 w-24 items-center justify-center rounded-2xl bg-white">
          <img src="@/assets/mnts-logo.png" alt="MNTS logo" class="h-20 w-20 object-contain" />
        </span>
        <p class="text-xs uppercase tracking-[0.2em] text-slate-300">Welcome</p>
      </div>
      <h1 class="mt-3 text-3xl font-semibold">MNTS Asset Management</h1>
      <p class="mt-2 text-sm text-slate-200">
        Sign in with your MNTS or MNTS Tamil School Google Account to continue.
      </p>

      <div class="mt-4 w-full space-y-3 text-sm">
        <p v-if="sessionStore.loading" class="text-slate-400">Authenticating...</p>
        <p v-else-if="oauthError" class="text-rose-300">
          {{ oauthError }}
        </p>
        <p v-else-if="sessionStore.error" class="text-rose-300">
          {{ sessionStore.error }}
        </p>
        <p v-else-if="sessionStore.message" class="text-emerald-300">
          {{ sessionStore.message }}
        </p>
      </div>

      <div class="mt-6 w-full space-y-4">
        <Button
          type="button"
          variant="outline"
          class="w-full border-slate-200 bg-white text-slate-900 hover:bg-slate-100"
          :disabled="sessionStore.loading"
          @click="handleGoogleSignIn"
        >
          <svg
            class="mr-2 h-4 w-4"
            viewBox="0 0 48 48"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
          >
            <path
              d="M44.5 24.5c0-1.6-.14-2.76-.38-3.96H24v7.46h11.82c-.24 1.84-1.55 4.62-4.46 6.48l-.04.26 6.36 4.93.44.04c4.06-3.74 6.38-9.24 6.38-15.2Z"
              fill="#4285F4"
            />
            <path
              d="M24 45c5.84 0 10.74-1.92 14.32-5.22l-6.82-5.26c-1.82 1.28-4.26 2.18-7.5 2.18-5.72 0-10.56-3.74-12.28-8.92l-.25.02-6.6 5.2-.09.24C8.32 40.82 15.68 45 24 45Z"
              fill="#34A853"
            />
            <path
              d="M11.72 27.78a12.9 12.9 0 0 1-.68-4.18c0-1.46.26-2.86.66-4.18l-.02-.28-6.68-5.28-.22.1A21.1 21.1 0 0 0 2.5 23.6c0 3.4.82 6.62 2.26 9.46l6.96-5.28Z"
              fill="#FBBC05"
            />
            <path
              d="M24 10.3c3.74 0 6.26 1.62 7.7 2.98l5.62-5.48C34.72 5.08 29.84 3 24 3 15.68 3 8.32 7.18 4.78 13.96l6.92 5.46C13.44 14.04 18.28 10.3 24 10.3Z"
              fill="#EA4335"
            />
          </svg>
          Sign in with Google
        </Button>
      </div>
    </div>
  </section>
</template>
