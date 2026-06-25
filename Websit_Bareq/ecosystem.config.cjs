module.exports = {
  apps: [{
    name: 'albareq',
    script: 'dist/index.cjs',
    cwd: '/var/www/Pr_Albareq/albareq',
    env: { PORT: '5001' },
    instances: 1,
    exec_mode: 'fork',
    autorestart: true,
    watch: false
  }]
};
