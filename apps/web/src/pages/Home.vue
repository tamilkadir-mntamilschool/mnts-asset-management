<script setup lang="ts">
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
</script>

<template>
  <section>
    <div class="mx-auto flex w-full max-w-5xl flex-col gap-10 px-6 py-12">
      <header class="space-y-3">
        <p class="text-xs uppercase tracking-[0.25em] text-slate-400">MNTS Asset Management</p>
        <h1 class="text-4xl font-semibold tracking-tight sm:text-5xl">
          Every asset, fully tracked.
        </h1>
        <p class="max-w-2xl text-base text-slate-300 sm:text-lg">
          Track inventory, condition, and workflows in one place with real-time status
          and clean audit trails.
        </p>
      </header>

      <section class="grid gap-6 sm:grid-cols-2">
        <div class="rounded-2xl border border-slate-800 bg-slate-900/60 p-6">
          <h2 class="text-lg font-semibold">Inventory</h2>
          <p class="mt-2 text-sm text-slate-300">
            Capture assets, assign categories, and monitor loans in real time.
          </p>
        </div>
        <div class="rounded-2xl border border-slate-800 bg-slate-900/60 p-6">
          <h2 class="text-lg font-semibold">Event checkouts</h2>
          <p class="mt-2 text-sm text-slate-300">
            Build event kits, assign custodians, and track returns.
          </p>
        </div>
      </section>

      <section class="rounded-2xl border border-slate-800 bg-slate-900/60 p-6">
        <h2 class="text-lg font-semibold">Request early access</h2>
        <p class="mt-2 text-sm text-slate-300">
          Get notified when the first workspace is ready.
        </p>
        <div class="mt-4 flex flex-col gap-3 sm:flex-row">
          <Input
            class="sm:max-w-xs"
            type="email"
            placeholder="you@company.com"
          />
          <Button class="bg-slate-100 text-slate-950 hover:bg-white">
            Join the list
          </Button>
        </div>
      </section>
    </div>
  </section>
</template>
