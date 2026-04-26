<template>
  <div class="app-container keyword-send-audit">
    <content-review :embedded="true" />
  </div>
</template>

<script>
import ContentReview from '@/views/business/contentReview/index.vue'

export default {
  name: 'KeywordSendAudit',
  components: { ContentReview }
}
</script>
