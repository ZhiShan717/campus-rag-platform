import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import { createMemoryHistory, createRouter } from 'vue-router'

import App from '../App.vue'

const StubPage = { template: '<div>stub</div>' }

async function mountApp() {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/qa', name: 'qa', component: StubPage },
      { path: '/documents', name: 'documents', component: StubPage },
      { path: '/admin', name: 'admin', component: StubPage },
      { path: '/evaluation', name: 'evaluation', component: StubPage },
    ],
  })
  await router.push('/qa')
  await router.isReady()
  return mount(App, { global: { plugins: [router] } })
}

describe('App', () => {
  it('renders the shell title and navigation', async () => {
    const wrapper = await mountApp()
    expect(wrapper.text()).toContain('校园知识库')
    expect(wrapper.text()).toContain('知识问答')
    expect(wrapper.text()).toContain('文档管理')
    expect(wrapper.text()).toContain('后台管理')
    expect(wrapper.text()).toContain('质量评测')
  })
})
