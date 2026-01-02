<script setup lang="ts">
import { computed, ref, watchEffect } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useSessionStore } from '@/stores/session'

const sessionStore = useSessionStore()
const email = ref('')
const password = ref('')
const newPassword = ref('')
const mode = ref<'signIn' | 'signUp' | 'reset' | 'updatePassword'>('signIn')
const route = useRoute()
const router = useRouter()

const isRecovery = computed(() => route.hash.includes('type=recovery'))

watchEffect(() => {
  if (isRecovery.value) {
    mode.value = 'updatePassword'
  }
})

const handleSignIn = async () => {
  await sessionStore.signInWithPassword(email.value, password.value)
  if (!sessionStore.error) {
    await router.push((route.query.redirect as string) || '/assets')
  }
}

const handleGoogleSignIn = async () => {
  await sessionStore.signInWithGoogle()
}

const handleSignUp = async () => {
  await sessionStore.signUp(email.value, password.value)
  if (!sessionStore.error && sessionStore.status !== 'pending_confirmation') {
    await router.push('/assets')
  }
}

const handleReset = async () => {
  await sessionStore.requestPasswordReset(email.value)
}

const handleUpdatePassword = async () => {
  await sessionStore.updatePassword(newPassword.value)
  if (!sessionStore.error) {
    mode.value = 'signIn'
    newPassword.value = ''
  }
}
</script>

<template>
  <section class="mx-auto w-full max-w-md px-6 py-16">
    <div class="rounded-3xl border border-slate-800/80 bg-slate-900/60 p-8 shadow-xl shadow-slate-950/40">
      <p class="text-xs uppercase tracking-[0.2em] text-slate-300">Access</p>
      <h1 class="mt-3 text-3xl font-semibold">
        <span v-if="mode === 'signIn'">Sign in to MNTS</span>
        <span v-else-if="mode === 'signUp'">Create your account</span>
        <span v-else-if="mode === 'reset'">Reset your password</span>
        <span v-else>Set a new password</span>
      </h1>
      <p class="mt-2 text-sm text-slate-200">
        <span v-if="mode === 'signIn'">
          Use your email and password. New teams can create an account.
        </span>
        <span v-else-if="mode === 'signUp'">
          Create an account for your workspace. Confirm via the email link if required.
        </span>
        <span v-else-if="mode === 'reset'">
          We will email you a recovery link to set a new password.
        </span>
        <span v-else>
          Enter a new password to finish recovery.
        </span>
      </p>

      <div class="mt-4 space-y-3 text-sm">
        <p v-if="sessionStore.loading" class="text-slate-400">Authenticating...</p>
        <p v-else-if="sessionStore.error" class="text-rose-300">
          {{ sessionStore.error }}
        </p>
        <p v-else-if="sessionStore.message" class="text-emerald-300">
          {{ sessionStore.message }}
        </p>
      </div>

      <form class="mt-6 space-y-4">
        <div v-if="mode === 'signIn' || mode === 'signUp'" class="space-y-3">
          <Button
            type="button"
            variant="outline"
            class="border-slate-700 text-slate-100 hover:bg-slate-800/70"
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
            Continue with Google
          </Button>
          <div class="flex items-center gap-3 text-xs text-slate-500">
            <div class="h-px flex-1 bg-slate-800"></div>
            <span>or</span>
            <div class="h-px flex-1 bg-slate-800"></div>
          </div>
        </div>
        <div v-if="mode !== 'updatePassword'" class="grid gap-2">
          <Label for="auth-email">Email</Label>
          <Input id="auth-email" v-model="email" type="email" placeholder="you@company.com" />
        </div>
        <div v-if="mode === 'signIn' || mode === 'signUp'" class="grid gap-2">
          <Label for="auth-password">Password</Label>
          <Input id="auth-password" v-model="password" type="password" placeholder="Enter your password" />
        </div>
        <div v-if="mode === 'updatePassword'" class="grid gap-2">
          <Label for="auth-new-password">New password</Label>
          <Input id="auth-new-password" v-model="newPassword" type="password" placeholder="Create a new password" />
        </div>

        <div v-if="mode === 'signIn'" class="flex flex-col gap-3">
          <Button
            type="button"
            class="bg-amber-300 text-slate-950 hover:bg-amber-200"
            :disabled="sessionStore.loading"
            @click="handleSignIn"
          >
            Sign in
          </Button>
          <Button
            type="button"
            variant="outline"
            class="border-slate-700 text-slate-100 hover:bg-slate-800/70"
            :disabled="sessionStore.loading"
            @click="mode = 'signUp'"
          >
            Create account
          </Button>
          <button
            class="text-xs text-slate-300 transition hover:text-white"
            type="button"
            @click="mode = 'reset'"
          >
            Forgot your password?
          </button>
        </div>

        <div v-else-if="mode === 'signUp'" class="flex flex-col gap-3">
          <Button
            type="button"
            class="bg-amber-300 text-slate-950 hover:bg-amber-200"
            :disabled="sessionStore.loading"
            @click="handleSignUp"
          >
            Create account
          </Button>
          <Button
            type="button"
            variant="outline"
            class="border-slate-700 text-slate-100 hover:bg-slate-800/70"
            :disabled="sessionStore.loading"
            @click="mode = 'signIn'"
          >
            Back to sign in
          </Button>
        </div>

        <div v-else-if="mode === 'reset'" class="flex flex-col gap-3">
          <Button
            type="button"
            class="bg-amber-300 text-slate-950 hover:bg-amber-200"
            :disabled="sessionStore.loading"
            @click="handleReset"
          >
            Send reset email
          </Button>
          <Button
            type="button"
            variant="outline"
            class="border-slate-700 text-slate-100 hover:bg-slate-800/70"
            :disabled="sessionStore.loading"
            @click="mode = 'signIn'"
          >
            Back to sign in
          </Button>
        </div>

        <div v-else class="flex flex-col gap-3">
          <Button
            type="button"
            class="bg-amber-300 text-slate-950 hover:bg-amber-200"
            :disabled="sessionStore.loading"
            @click="handleUpdatePassword"
          >
            Update password
          </Button>
          <Button
            type="button"
            variant="outline"
            class="border-slate-700 text-slate-100 hover:bg-slate-800/70"
            :disabled="sessionStore.loading"
            @click="mode = 'signIn'"
          >
            Back to sign in
          </Button>
        </div>
      </form>
    </div>
  </section>
</template>
