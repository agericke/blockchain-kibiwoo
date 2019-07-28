App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',

  init: function() {
    // Load pets.
    $.getJSON('./../kibiwoo_products.json', function(data) {
      var productsRow = $('#productsRow');
      var productTemplate = $('#productTemplate');

      for (i = 0; i < data.length; i ++) {
        productTemplate.find('.panel-title').text(data[i].name);
        productTemplate.find('img').attr('src', data[i].picture);
        productTemplate.find('.product-name').text(data[i].name);
        productTemplate.find('.product-category').text(data[i].category);
        productTemplate.find('.product-sku').text(data[i].sku);
        productTemplate.find('.product-location').text(data[i].location);
        productTemplate.find('.btn-book').attr('data-id', data[i].id);

        productsRow.append(productTemplate.html());
      }
    });

    return App.initWeb3();
  },

  initWeb3: async function() {

    // Modern dapp browsers...
    if (window.ethereum) {
      App.web3Provider = window.ethereum;
      try {
        // Request account address
        await window.ethereum.enable();
      } catch (error) {
        // User denied account access...
        console.error("User denied account access");
      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
    }
    // If no injected web3 instance is detected, fall back to Ganache
    else {
      // This fallback is fine for development environments, but insecure and not suitable for production
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
    }
    web3 = new Web3(App.web3Provider);
    return App.initContract();
  },

  initContract: function() {
    $.getJSON("Kibiwoo.json", function(kibiwooArtifact) {
      // Instantiate a new truffle contract from the artifact
      App.contracts.Kibiwoo = TruffleContract(kibiwooArtifact);
      // Connect provider to interact with contract
      App.contracts.Kibiwoo.setProvider(App.web3Provider);

      return App.render();
    });

    return App.bindEvents();
  },

  render: function() {
    var kibiwooInstance;
    // var loader = $("#loader");
    // var content = $("#content");

    // loader.show();
    // content.hide();

    // Load account data
    web3.eth.getCoinbase(function(err, account) {
      if (err === null) {
        App.account = account;
        $("#accountAddress").html("Your Account: " + account);
      }
    });

    // Load contract data
    App.contracts.Kibiwoo.deployed().then(function(instance) {
      kibiwooInstance = instance;
      return kibiwooInstance.getProductsCount();
    }).then(async function(productsCount) {

      console.log("Total products equal to "+productsCount)
      if (productsCount == 0) {
        for (i = 0; i < 16; i++) {
          await kibiwooInstance.createNewProduct('Producto'+i, 0, {from: App.account});
        }
      }

    }).catch(function(error) {
      console.warn(error);
    });

    return App.markBooked();
  },

  bindEvents: function() {
    $(document).on('click', '.btn-book', App.bookProduct);
  },

  markBooked: function(adopters, account) {
    
    var kibiwooInstance;

    App.contracts.Kibiwoo.deployed().then(function(instance) {
      kibiwooInstance = instance;

      return kibiwooInstance.getProductsCount();
    }).then(async function(products) {
      var isbook;
      console.log("\n\nin hereeee");
      for (i = 0; i < products; i++) {
        isbook = await kibiwooInstance.isBooked(i);
        console.log("Book is ");
        console.log(isbook);
        if (isbook) {
          $('.panel-product').eq(i).find('.product-booked').text('True');
          $('.panel-product').eq(i).find('button').text('Booked').attr('disabled', true);
        }
      }
    }).catch(function(err) {
      console.log(err.message);
    });
  },

  bookProduct: function(event) {

    event.preventDefault();

    var productId = parseInt($(event.target).data('id'));

    var kibiwooInstance;

    App.contracts.Kibiwoo.deployed().then(function(instance) {
      kibiwooInstance = instance;

      // Execute adopt as a transaction by sending account
      return kibiwooInstance.book(productId, {from: App.account});
    }).then(function(result) {
      return App.markBooked();
    }).catch(function(err) {
      console.log(err.message);
    });
  }
};

$(function() {
  $(window).load(function() {
    App.init();
  });
});