<template>
  <Line ref="canvas"></Line>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted, PropType } from 'vue'
import { Line } from 'vue-chartjs'
import { Chart as ChartJS, registerables } from 'chart.js'

ChartJS.register(...registerables)

export default defineComponent({
  components: {
    Line
  },
  props: {
    increase: {
      type: Boolean,
      required: true
    },
    datasets: {
      type: Array as PropType<number[]>,
      required: true
    }
  },
  setup(props) {
    const canvas = ref<HTMLCanvasElement | null>(null)
    const gradient = ref<CanvasGradient | null>(null)
    const gradient2 = ref<CanvasGradient | null>(null)

    onMounted(() => {
      if (canvas.value) {
        const ctx = canvas.value.getContext('2d')
        if (ctx) {
          gradient.value = ctx.createLinearGradient(0, 0, 0, 450)
          gradient.value.addColorStop(0.1119, 'rgba(95, 223, 146, 0.5)')
          gradient.value.addColorStop(0.1118, 'rgba(95, 223, 146, 0.3)')
          gradient.value.addColorStop(0.93, 'rgba(196, 196, 196, 0)')

          gradient2.value = ctx.createLinearGradient(0, 0, 0, 450)
          gradient2.value.addColorStop(0, 'rgba(255, 189, 189, 0.5)')
          gradient2.value.addColorStop(0.94, 'rgba(196, 196, 196, 0)')

          const data = {
            labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July'],
            datasets: [
              {
                label: 'Data One',
                borderColor: props.increase ? '#28C165' : '#F4574D',
                borderWidth: 1,
                backgroundColor: props.increase ? gradient.value : gradient2.value,
                data: props.datasets
              }
            ]
          }

          const options = {
            responsive: true,
            maintainAspectRatio: false,
            legend: {
              display: false
            },
            elements: {
              point: {
                radius: 0
              }
            },
            tooltips: {
              callbacks: {
                label: (tooltipItem: any) => {
                  return tooltipItem.yLabel
                }
              }
            },
            scales: {
              yAxes: [
                {
                  ticks: {
                    display: false
                  },
                  gridLines: {
                    display: false,
                    drawBorder: false,
                    color: 'rgba(0, 0, 0, 0)'
                  }
                }
              ],
              xAxes: [
                {
                  ticks: {
                    display: false
                  },
                  gridLines: {
                    display: false,
                    drawBorder: false,
                    color: 'rgba(0, 0, 0, 0)'
                  }
                }
              ]
            }
          }

          new ChartJS(ctx, {
            type: 'line',
            data,
            options
          })
        }
      }
    })

    return {
      canvas
    }
  }
})
</script>

<style scoped>
canvas {
  width: 100%;
  height: 100%;
}
</style>
