<template>
  <TransitionRoot as="template" :show="modalActive">
    <Dialog class="relative z-10 mb-6" @close="modalActive = false">
      <TransitionChild
        as="template"
        enter="ease-out duration-300"
        enter-from="opacity-0"
        enter-to="opacity-100"
        leave="ease-in duration-200"
        leave-from="opacity-100"
        leave-to="opacity-0"
      >
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" />
      </TransitionChild>

      <div class="fixed inset-0 z-10 w-screen overflow-y-auto">
        <div
          class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0"
        >
          <TransitionChild
            as="template"
            enter="ease-out duration-300"
            enter-from="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
            enter-to="opacity-100 translate-y-0 sm:scale-100"
            leave="ease-in duration-200"
            leave-from="opacity-100 translate-y-0 sm:scale-100"
            leave-to="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
          >
            <DialogPanel
              class="relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg"
            >
              <!-- Close button -->
              <button
                @click="closeModal"
                class="absolute top-0 right-0 m-4 text-gray-400 hover:text-gray-500 focus:outline-none"
              >
                <span class="sr-only">Close</span>
                <svg
                  class="h-6 w-6"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  aria-hidden="true"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>

              <section class="bg-gray-50 dark:bg-gray-900">
                <div
                  class="flex flex-col items-center justify-center px-6 py-8 mx-auto md:h-screen lg:py-0"
                >
                  <div
                    class="w-full bg-white rounded-lg shadow dark:border md:mt-0 sm:max-w-md xl:p-0 dark:bg-gray-800 dark:border-gray-700"
                  >
                    <div class="p-6 space-y-4 md:space-y-6 sm:p-8">
                      <h1
                        class="text-xl font-bold leading-tight tracking-tight text-gray-900 md:text-2xl dark:text-white"
                      >
                        Create your account
                      </h1>
                      <form class="space-y-4 md:space-y-6" @submit.prevent="register">
                        <div>
                          <label
                            for="Your email"
                            class="block mb-2 text-sm font-medium text-gray-900 dark:text-white"
                            >Your email</label
                          >
                          <input
                            type="email"
                            name="email"
                            id="email"
                            v-model="email"
                            class="bg-gray-50 border border-gray-300 text-gray-900 sm:text-sm rounded-lg focus:ring-primary-600 focus:border-primary-600 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                            placeholder="example@abc.com"
                            required=""
                          />
                        </div>
                        <div>
                          <label
                            for="password"
                            class="block mb-2 text-sm font-medium text-gray-900 dark:text-white"
                            >Password</label
                          >
                          <input
                            type="password"
                            name="password"
                            id="password"
                            v-model="password"
                            placeholder="••••••••"
                            class="bg-gray-50 border border-gray-300 text-gray-900 sm:text-sm rounded-lg focus:ring-primary-600 focus:border-primary-600 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                            required=""
                          />
                        </div>

                        <div>
                          <label
                            for="Confirm Password"
                            class="block mb-2 text-sm font-medium text-gray-900 dark:text-white"
                            >Confirm Password</label
                          >
                          <input
                            type="password"
                            name="confirm_password"
                            id="confirmPassword"
                            v-model="confirmPassword"
                            placeholder="••••••••"
                            class="bg-gray-50 border border-gray-300 text-gray-900 sm:text-sm rounded-lg focus:ring-primary-600 focus:border-primary-600 block w-full p-2.5 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                            required=""
                          />
                        </div>

                        <button
                          type="submit"
                          class="w-full text-white bg-primary-600 hover:bg-primary-700 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
                        >
                          Sign up
                        </button>
                        <p class="text-sm font-light text-gray-500 dark:text-gray-400">
                          You already have an account yet?
                          <a
                            href="#"
                            class="font-medium text-primary-600 hover:underline dark:text-primary-500"
                            >Login here</a
                          >
                        </p>

                        <div class="bg-gray-50 px-4 py-3 sm:flex sm:flex-row-reverse sm:px-6">
                          <button
                            type="submit"
                            class="btn max-w-full px-8 py-4 bg-gradient-to-r from-[#468ef9] to-[#0c66ee] border border-[#0c66ee] text-white"
                          >
                            Submit
                          </button>
                        </div>
                      </form>
                    </div>
                  </div>
                </div>
              </section>
              <!-- <LoginModal></LoginModal> -->
            </DialogPanel>
          </TransitionChild>
        </div>
      </div>
    </Dialog>
  </TransitionRoot>
</template>

<script lang="ts">
import { defineComponent, ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from './supabase/supabase'
import LoginModal from './LoginModal.vue'
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'

export default defineComponent({
  components: {
    Dialog,
    DialogPanel,
    DialogTitle,
    TransitionChild,
    TransitionRoot,

    LoginModal
  },
  props: {
    modalActive: {
      type: Boolean,
      default: false
    }
  },
  setup(props, { emit }) {
    // Create data / vars
    const router = useRouter()
    const email = ref(null)
    const password = ref(null)
    const confirmPassword = ref(null)
    const errorMsg = ref(null)

    const closeModal = () => {
      emit('update:modalActive', false)
    }

    const register = async () => {
      if (password.value === confirmPassword.value) {
        try {
          const { error } = await supabase.auth.signUp(
            {
              email: email.value,
              password: password.value
            },
            {
              emailRedirectTo: 'http://localhost:3000/dashboard' // Adjust this if needed
            }
          )
          if (error) throw error

          console.log('registration successful')
          // Redirect to a verification page if needed
          router.push({ name: 'verification' })
        } catch (error) {
          errorMsg.value = error.message
          setTimeout(() => {
            errorMsg.value = null
          }, 5000)
        }
        return
      }
      // errorMsg.value = 'Error: Passwords do not match'
      setTimeout(() => {
        errorMsg.value = null
      }, 5000)
    }

    return {
      email,
      password,
      confirmPassword,
      errorMsg,
      register,
      closeModal
    }
  }
})
</script>
