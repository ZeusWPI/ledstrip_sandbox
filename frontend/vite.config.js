/**
 * @type {import("vite").UserConfig}
 */
const config = {
    build: {
        target: "es2022"
    },
    server: {
        proxy: {
            '/api': {
                target: 'http://ledstrip',
                changeOrigin: true,
                secure: false,
            },
            cors: false,
        },
    },
};

export default config;