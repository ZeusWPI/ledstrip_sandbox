/**
 * @type {import('vite').UserConfig}
 */
const config = {
    server: {
        proxy: {
            '/api': {
                target: 'http://localhost:8080',
                changeOrigin: true,
                secure: false,
            },
            cors: false
        },
    },
};

export default config;