/**
 * @type {import('vite').UserConfig}
 */
const config = {
    server: {
        proxy: {
            '/api': {
                target: 'http://ledstrip',
                changeOrigin: true,
                secure: false,
            },
            cors: false
        },
    },
};

export default config;