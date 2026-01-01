<template>
  <div class="mx-auto flex w-full max-w-6xl flex-col gap-6 px-6 py-10 lg:flex-row">
    <aside class="w-full rounded-3xl border border-slate-800 bg-slate-900/60 p-6 lg:w-64">
      <p class="text-xs uppercase tracking-[0.2em] text-slate-400">Workspace</p>
      <h2 class="mt-3 text-lg font-semibold">Operations</h2>
      <nav class="mt-4 flex flex-col gap-2 text-sm text-slate-300">
        <RouterLink class="rounded-lg px-3 py-2 transition hover:bg-slate-800/60 hover:text-slate-100" to="/assets">
          Assets
        </RouterLink>
      </nav>
      <div class="mt-6 rounded-2xl border border-slate-800 bg-slate-950/70 p-4 text-xs text-slate-400">
        <p class="font-semibold text-slate-200">Next sync</p>
        <p class="mt-1">Assets • 15:00 UTC</p>
      </div>
    </aside>
    <section class="flex-1">
      <slot />
    </section>
  </div>
</template>
