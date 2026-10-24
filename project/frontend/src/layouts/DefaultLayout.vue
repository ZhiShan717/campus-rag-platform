<script setup lang="ts">
import { RouterLink } from 'vue-router'

const navItems = [
  { name: 'qa', label: '知识问答', to: { name: 'qa' } },
  { name: 'documents', label: '文档管理', to: { name: 'documents' } },
  { name: 'admin', label: '后台管理', to: { name: 'admin' } },
  { name: 'evaluation', label: '质量评测', to: { name: 'evaluation' } },
] as const
</script>

<template>
  <div class="app-shell">
    <header class="app-header">
      <span class="app-title">校园知识库</span>
      <nav class="app-nav">
        <RouterLink v-for="item in navItems" :key="item.name" :to="item.to" class="app-nav-link">
          {{ item.label }}
        </RouterLink>
      </nav>
    </header>
    <main class="app-main">
      <slot />
    </main>
  </div>
</template>

<style scoped>
.app-shell {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.app-header {
  display: flex;
  align-items: center;
  gap: 2rem;
  padding: 0 1.5rem;
  height: 3.5rem;
  border-bottom: 1px solid #e5e7eb;
}

.app-title {
  font-weight: 600;
}

.app-nav {
  display: flex;
  gap: 1.25rem;
}

.app-nav-link {
  color: #4b5563;
  text-decoration: none;
}

.app-nav-link.router-link-active {
  color: #1d4ed8;
  font-weight: 600;
}

.app-main {
  flex: 1;
  padding: 1.5rem;
}
</style>
