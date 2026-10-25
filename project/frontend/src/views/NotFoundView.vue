<script setup lang="ts">
import { RouterLink } from 'vue-router'
</script>

<template>
  <section class="page">
    <h1>页面不存在</h1>
    <p class="page-hint">地址可能输入有误。</p>
    <RouterLink to="/qa">返回知识问答</RouterLink>
  </section>
</template>

<style scoped>
.page-hint {
  color: #6b7280;
}
</style>
