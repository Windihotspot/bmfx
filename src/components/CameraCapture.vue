<template>
  <div class="row" ref="cameraCaptureIntRef">
    <!-- Use the .row class to contain columns -->
    <div class="col-md-5">
      <!-- Use .col-md-4 for a column that takes up 4 out of 12 -->
      <!-- Upload Photo ID Button -->
      <div class="mb-3">
        <!-- Add a margin bottom to stack buttons vertically -->
        <v-btn variant="text" color="primary" @click.prevent="showPhotoIDModal = true" class="text-2xl"> Take a selfie </v-btn>
      </div>
    </div>

    <div class="w-full md:w-7/12">
      <!-- Filename display and cancel button for Photo ID -->
      <div
        v-if="photoID"
        class="bg-blue-50 border border-blue-200 p-2 rounded-lg flex justify-between items-center mb-4"
      >
        <span
          @click="showCapturedImage(photoID.src, 'photoID')"
          class="text-blue-700 font-semibold hover:underline cursor-pointer"
        >
          {{ photoID.name }}
        </span>
        <button
          type="button"
          class="text-red-600 hover:text-red-800 focus:outline-none"
          @click="photoID = null"
        >
          &times;
        </button>
      </div>

      <!-- Filename display and cancel button for Proof of Address -->
      <div
        v-if="proofOfAddress"
        class="bg-blue-50 border border-blue-200 p-2 rounded-lg flex justify-between items-center"
      >
        <span
          @click="showCapturedImage(proofOfAddress.src, 'proofofAddress')"
          class="text-blue-700 font-semibold hover:underline cursor-pointer"
        >
          {{ proofOfAddress.name }}
        </span>
        <button
          type="button"
          class="text-red-600 hover:text-red-800 focus:outline-none"
          @click="proofOfAddress = null"
        >
          &times;
        </button>
      </div>
    </div>

    <!-- Camera capture modal -->
    <CameraModal
      ref="cameraCaptureModal"
      :showCameraModal="showPhotoIDModal || showProofOfAddressModal"
      @update:showCameraModal="handleModalVisibility"
      @imageCaptured="handleImageCaptured"
    ></CameraModal>
  </div>
</template>

<script lang="ts" setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import CameraModal from './CameraModal.vue'

const showPhotoIDModal = ref(false)
const showProofOfAddressModal = ref(false)
const cameraCaptureModal = ref(null)
const cameraCaptureIntRef = ref(null)

type DocumentType = {
  name: string
  src: any
} | null

const photoID = ref<DocumentType>(null)
const proofOfAddress = ref<DocumentType>(null)

const emit = defineEmits(['photoId', 'proofOfAddress'])

function showCapturedImage(imageSrc, label) {
  console.log('showCapturedImage: ') // , imageSrc
  if (imageSrc == '' || imageSrc == null) {
    console.log('imageSrc is empty ')
    return
  }
  if (cameraCaptureModal.value) {
    if (label == 'photoID') showPhotoIDModal.value = true
    // or set a new state variable to true if needed
    else if (label == 'proofofAddress') showProofOfAddressModal.value = true // or set a new state variable to true if needed

    cameraCaptureModal.value.showCapturedImage(imageSrc)
  }
}

const stopCameraStream = () => {
  if (cameraCaptureModal.value) {
    cameraCaptureModal.value.clearImageViewer()
    cameraCaptureModal.value.stopCameraStream()
  }
}

function handleModalVisibility(value) {
  console.log('handling cameraint modal visibility')
  if (!value) closeAllModals()
  showPhotoIDModal.value = value
  showProofOfAddressModal.value = value
}

function handleImageCaptured(imageSrc) {
  console.log('handling cameraint imagecapture event')
  if (showPhotoIDModal.value) {
    photoID.value = { name: 'Photo ID', src: imageSrc }
    updatePhotoId(photoID.value)
  } else if (showProofOfAddressModal.value) {
    proofOfAddress.value = { name: 'Proof of Address', src: imageSrc }
    updateProofOfAddress(proofOfAddress.value)
  }
}

const updatePhotoId = (photoIdData) => {
  console.log('updating photoid file ... ', photoIdData)
  // Convert photoIdData.src to a File object and update photoidfile
  // You need to create a File object from the Base64 data URL
  let _photoid = convertDataUrlToFile(photoIdData.src, 'photoId.png')
  emit('photoId', _photoid)

  reinitStackeModals()
}

const updateProofOfAddress = (proofOfAddressData) => {
  console.log('updating proofofaddress file ... ', proofOfAddressData)
  // Convert proofOfAddressData.src to a File object and update poaddressfile
  // You need to create a File object from the Base64 data URL
  let _proofofAddress = convertDataUrlToFile(proofOfAddressData.src, 'proofOfAddress.png')
  emit('proofOfAddress', _proofofAddress)

  reinitStackeModals()
}

// Utility function to convert a data URL to a File object
function convertDataUrlToFile(dataUrl, filename) {
  const arr = dataUrl.split(',')
  const mime = arr[0].match(/:(.*?);/)[1]
  const bstr = atob(arr[1])
  let n = bstr.length
  const u8arr = new Uint8Array(n)

  while (n--) {
    u8arr[n] = bstr.charCodeAt(n)
  }

  return new File([u8arr], filename, { type: mime })
}

// Add event listener to modal for 'hidden.bs.modal' event
onMounted(() => {
  initStackedModals()
  // Find the closest parent modal of the component
  const modalElement = cameraCaptureIntRef.value?.closest('.modal')
  if (modalElement) {
    modalElement.addEventListener('hidden.bs.modal', stopCameraStream)
  }
})

// Remove event listener when component is unmounted
onUnmounted(() => {
  modalReferences.value.forEach(({ element, onClick }) => {
    element.removeEventListener('click', onClick) // Remove event listener
  })

  // Find the closest parent modal of the component
  const modalElement = cameraCaptureIntRef.value?.closest('.modal')
  if (modalElement) {
    modalElement.removeEventListener('hidden.bs.modal', stopCameraStream)
  }
})

const modalReferences = ref([])

// Function to close all modals
const closeAllModals = () => {
  modalReferences.value.forEach(({ element }) => {
    const modalEl = document.querySelector(element.getAttribute('data-bs-stacked-modal'))
    if (modalEl && modalEl.classList.contains('show')) {
      const modalInstance = Modal.getInstance(modalEl)
      if (modalInstance) modalInstance.hide()
    }
  })
}

// Function to clear existing modal references
const clearModalReferences = () => {
  modalReferences.value.forEach(({ element, onClick }) => {
    element.removeEventListener('click', onClick) // Remove event listener
  })
  modalReferences.value = [] // Clear the references array
}

const reinitStackeModals = async () => {
  await nextTick()
  await initStackedModals()
}

// Function to initialize stacked modals
const initStackedModals = () => {
  const elements = document.querySelectorAll('[data-bs-stacked-modal]')

  // Clear any existing modal references before initializing
  clearModalReferences()

  elements.forEach((element) => {
    console.log('stackedmodal btn elements', element)
    const onClick = (e) => {
      e.preventDefault()
      closeAllModals()

      const modalEl = document.querySelector(element.getAttribute('data-bs-stacked-modal'))
      console.log('stacked item', element.getAttribute('data-bs-stacked-modal'))

      if (modalEl && !modalEl.classList.contains('show')) {
        console.log('adding class=show', modalEl)
        const modalInstance = new Modal(modalEl)
        modalInstance.show()
        console.log('staring to show modal instance', modalInstance)
      }
    }

    element.addEventListener('click', onClick)

    modalReferences.value.push({ element, onClick }) // Store for cleanup
  })
}
</script>

<style scoped>
#kt_modal_camera .modal-body {
  overflow: hidden !important;
}

.clickable {
  cursor: pointer;
  text-decoration: underline;
}
.v-btn{
  text-transform: none;
}
</style>
