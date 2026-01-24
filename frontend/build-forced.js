// build-forced.js
import { build } from "vite";
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

const config = defineConfig({
  build: {
    outDir: "../dist/frontend",
    minify: false,
    sourcemap: true,
    rollupOptions: {
      onwarn(warning, warn) {
        // Ignorar todos los warnings
        return;
      }
    }
  },
  esbuild: {
    // Ignorar errores de TypeScript
    legalComments: "none"
  }
});

build(config).catch(err => {
  console.error("Build falló:", err.message);
  process.exit(1);
});
