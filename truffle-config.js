module.exports = {
  networks: {
      development: {
          host: '127.0.0.1',
          port: 7545,
          network_id: '*',
          websockets: true

      },
  },

  solc: {
      optimizer: {
          enabled: true,
          runs: 200,
      },
  },

  compilers: {
      solc: {
          version: '0.5.2',
      },
  },
};
