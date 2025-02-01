"use client"

import type React from "react"
import { useEffect, useCallback, useState } from "react"
import { motion, useAnimation } from "framer-motion"

const ThunderStrike: React.FC = () => {
  const controls = useAnimation()
  const [lightningPath, setLightningPath] = useState("")

  const generateLightningPath = useCallback(() => {
    const points = []
    points.push("M32,6") // Start at the top center

    // Generate 3-5 random points
    const numPoints = Math.floor(Math.random() * 3) + 3
    for (let i = 0; i < numPoints; i++) {
      const x = Math.random() * 30 + 16 // Random x between 16 and 46
      const y = (i + 1) * (52 / (numPoints + 1)) + 6 // Distribute y evenly
      points.push(`L${x},${y}`)
    }

    points.push("L32,58") // End at the bottom center
    return points.join(" ")
  }, [])

  const pathVariants = {
    hidden: { pathLength: 0, opacity: 0 },
    visible: {
      pathLength: 1,
      opacity: 1,
      transition: {
        duration: 0.5,
        ease: "easeInOut",
      },
    },
  }

  const flashVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: [0, 0.5, 1, 0.5, 0],
      transition: {
        duration: 0.3,
        times: [0, 0.1, 0.2, 0.3, 1],
      },
    },
  }

  const circleVariants = {
    hidden: { strokeDashoffset: 188.5 },
    visible: {
      strokeDashoffset: 0,
      transition: {
        duration: 1.5,
        ease: "easeInOut",
      },
    },
  }

  const strikeThunder = useCallback(async () => {
    setLightningPath(generateLightningPath())
    await controls.start("visible")
    await controls.start("hidden")
    setTimeout(strikeThunder, 1000)
  }, [controls, generateLightningPath])

  useEffect(() => {
    strikeThunder()
  }, [strikeThunder])

  return (
    <div className="relative">
      <div className="absolute -inset-8">
        <div className="w-full h-full animate-pulse opacity-20">
          {/* Lightning bolt animation */}
        </div>
      </div>
      <div className="w-8 h-8 relative">
        <motion.div
          initial="hidden"
          animate={controls}
          variants={flashVariants}
          className="absolute inset-0 bg-emerald-400 rounded-full"
        />
        <svg viewBox="0 0 64 64" className="w-full h-full">
          <motion.circle
            cx="32"
            cy="32"
            r="30"
            fill="none"
            stroke="#047857"
            strokeWidth="3"
            strokeDasharray="188.5"
            initial="hidden"
            animate="visible"
            variants={circleVariants}
          />
          <motion.path
            d={lightningPath}
            fill="none"
            stroke="#047857"
            strokeWidth="3"
            initial="hidden"
            animate={controls}
            variants={pathVariants}
          />
        </svg>
      </div>
    </div>
  )
}

export const DataAgentThinking: React.FC = () => {
  return (
    <div className="flex items-center space-x-4 mb-4">
      <ThunderStrike />
      <div className="text-emerald-800">
        <p className="text-base font-medium leading-tight">Data Agent is cooking up a pipeline storm...</p>
        <p className="text-xs text-emerald-600 italic mt-1">Bytes are simmering, insights are brewing!</p>
      </div>
    </div>
  )
} 