import { defineStore } from 'pinia'
import type { Session, User } from '@supabase/supabase-js'
import { supabase } from '@/lib/supabase'

type AuthError = string | null
type AuthStatus = 'idle' | 'loading' | 'success' | 'error' | 'pending_confirmation'

const formatAuthError = (message: string) => {
  const normalized = message.toLowerCase()
  if (
    normalized.includes('signup') ||
    normalized.includes('sign up') ||
    normalized.includes('signups not allowed') ||
    normalized.includes('disabled') ||
    normalized.includes('not authorized') ||
    normalized.includes('unauthorized') ||
    normalized.includes('not permitted')
  ) {
    return 'Access denied. This Google account is not authorized.'
  }
  return message
}

let initPromise: Promise<void> | null = null
let authListenerAttached = false

const hydrateProfileFromIdentity = async (user: User | null) => {
  if (!user) return
  const currentName = user.user_metadata?.full_name as string | undefined
  if (currentName) return

  const identityData = user.identities?.find((identity) => identity.provider === 'google')?.identity_data as
    | { full_name?: string; name?: string }
    | undefined
  if (!identityData) return

  const nextName = currentName || identityData.full_name || identityData.name
  if (!nextName) return

  await supabase.auth.updateUser({
    data: {
      full_name: nextName,
    },
  })
}

export const useSessionStore = defineStore('session', {
  state: () => ({
    session: null as Session | null,
    user: null as User | null,
    loading: false,
    error: null as AuthError,
    initialized: false,
    status: 'idle' as AuthStatus,
    message: null as string | null,
    lastEvent: null as string | null,
  }),
  actions: {
    async init() {
      if (this.initialized) {
        return
      }

      if (!initPromise) {
        initPromise = (async () => {
          const { data } = await supabase.auth.getSession()
          this.session = data.session
          this.user = data.session?.user ?? null

          if (!authListenerAttached) {
            supabase.auth.onAuthStateChange((event, session) => {
              this.session = session
              this.user = session?.user ?? null
              this.lastEvent = event
              if (event === 'SIGNED_IN') {
                this.status = 'success'
                this.message = "You're signed in."
                void hydrateProfileFromIdentity(this.user)
              }
              if (event === 'SIGNED_OUT') {
                this.status = 'idle'
                this.message = null
              }
            })
            authListenerAttached = true
          }

          this.initialized = true
        })()
      }

      await initPromise
    },
    async signInWithPassword(email: string, password: string) {
      this.loading = true
      this.error = null
      this.status = 'loading'
      this.message = null
      const { error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) {
        this.error = error.message
        this.status = 'error'
        this.message = null
      } else {
        this.status = 'success'
        this.message = "You're signed in."
      }
      this.loading = false
    },
    async signInWithGoogle() {
      this.loading = true
      this.error = null
      this.status = 'loading'
      this.message = null
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: `${window.location.origin}/auth`,
        },
      })
      if (error) {
        this.error = formatAuthError(error.message)
        this.status = 'error'
        this.message = null
        this.loading = false
      } else {
        this.status = 'success'
        this.message = 'Redirecting to Google...'
      }
    },
    async signUp(email: string, password: string) {
      this.loading = true
      this.error = null
      this.status = 'loading'
      this.message = null
      const { data, error } = await supabase.auth.signUp({ email, password })
      if (error) {
        this.error = error.message
        this.status = 'error'
        this.message = null
      } else if (!data.session) {
        this.status = 'pending_confirmation'
        this.message = 'Check your email to confirm the account.'
      } else {
        this.status = 'success'
        this.message = 'Account created—welcome to MNTS Asset Management.'
      }
      this.loading = false
    },
    async signOut() {
      this.loading = true
      this.error = null
      this.status = 'loading'
      this.message = null
      const { error } = await supabase.auth.signOut()
      if (error) {
        this.error = error.message
        this.status = 'error'
        this.message = null
      } else {
        this.status = 'success'
        this.message = 'Signed out.'
      }
      this.loading = false
    },
    async requestPasswordReset(email: string) {
      this.loading = true
      this.error = null
      this.status = 'loading'
      this.message = null
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/auth`,
      })
      if (error) {
        this.error = error.message
        this.status = 'error'
        this.message = null
      } else {
        this.status = 'success'
        this.message = 'Password reset email sent.'
      }
      this.loading = false
    },
    async updatePassword(password: string) {
      this.loading = true
      this.error = null
      this.status = 'loading'
      this.message = null
      const { error } = await supabase.auth.updateUser({ password })
      if (error) {
        this.error = error.message
        this.status = 'error'
        this.message = null
      } else {
        this.status = 'success'
        this.message = 'Password updated.'
      }
      this.loading = false
    },
    async updateProfile(profile: { full_name?: string }) {
      this.loading = true
      this.error = null
      this.status = 'loading'
      this.message = null
      const { data, error } = await supabase.auth.updateUser({ data: profile })
      if (error) {
        this.error = error.message
        this.status = 'error'
        this.message = null
      } else {
        this.user = data.user ?? this.user
        this.status = 'success'
        this.message = 'Profile updated.'
      }
      this.loading = false
    },
  },
})
