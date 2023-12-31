module.exports = {
  
  networks: {
    development: {
          host: "127.0.0.1",
          port: 7545, // Porta padrão em que o ganache utiliza
          network_id: "*"
       }
  },

  compilers: {
    solc: {
      version: "0.5.16",
      optimizer: {
        enabled: true,
        runs: 200
     }
    }
  }
};
