// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../Roles/Consumer.sol";
import "../Roles/Distributor.sol";
import "../Roles/Supplier.sol";
import "../Roles/Trader.sol";

contract SupplyChain is Ownable, Consumer, Distributor, Supplier, Trader {
    using Counters for Counters.Counter;

    // for Stock Keeping Unit (SKU)
    Counters.Counter private sku;
    // for Universal Product Code (UPC)
    Counters.Counter private upc;
    // the VAT is 5% at this moment.
    uint256 constant VAT_PERCENTAGE = 5;

    // mappings

    // sku mapping
    mapping(uint256 => Product) skuToProduct;
    // upc mapping
    mapping(uint256 => Product) upcToProduct;
    // vat paid for product
    // sku to vat paid for products
    mapping(uint256 => uint256) paidVat;

    // events
    // TODO edit the events when changing the state

    event ProductCreated(
        uint256 indexed sku,
        uint256 price,
        address indexed supplier,
        uint256 paidVat
    );
    event ProductShipped(
        uint256 indexed sku,
        uint256 price,
        address indexed distributor,
        uint256 paidVat
    );
    event ProductDistributed(
        uint256 indexed sku,
        uint256 price,
        address indexed trader,
        uint256 paidVat
    );
    event ProductedSold(
        uint256 indexed sku,
        uint256 price,
        address indexed consumer,
        uint256 paidVat
    );
    event ProductedInStore(
        uint256 indexed sku,
        uint256 price,
        address indexed Trader,
        uint256 paidVat
    );

    // enum state for the product
    // TODO change the state

    enum State {
        Created,
        Shipped,
        Distributed,
        Traded,
        Sold
    }

    // the peoduct attributes
    struct Product {
        uint256 sku;
        uint256 upc;
        // combination of upc + sku
        uint256 productId;
        // value added tax
        uint256 vat;
        // the amount to be sent to zakat
        // which is the price 5% of the price the supplier/distributor/trader (minus) the amount paid before
        // amount.div(100).mul(5);
        uint256 vatToCollect;
        // the current state of the product
        State state;
        string nameOfTheProduct;
        string productNotes;
        // the price changes when the an event emitted (when selling the product)
        uint256 productPrice;
        // address throughout the process
        // the current owner
        address ownerAddress;
        address supplierAddress;
        address distributorAddress;
        address traderAddress;
        address consumerAddress;
    }
    // modifiers
    modifier verifyCaller(address _address) {
        require(_msgSender() == _address);
        _;
    }
    modifier created(uint256 _sku) {
        require(skuToProduct[_sku].state == State.Created);
        _;
    }
    modifier shipped(uint256 _sku) {
        require(skuToProduct[_sku].state == State.Shipped);
        _;
    }
    modifier distributed(uint256 _sku) {
        require(skuToProduct[_sku].state == State.Distributed);
        _;
    }
    modifier traded(uint256 _sku) {
        require(skuToProduct[_sku].state == State.Traded);
        _;
    }
    modifier sold(uint256 _sku) {
        require(skuToProduct[_sku].state == State.Sold);
        _;
    }

    // solidity has a problem with fractions
    modifier lessThan20(uint256 _price) {
        require(_price >= 20, "the price must be more than 20 Saudi Riyals");
        _;
    }

    constructor() {}

    function createProduct(
        string memory _nameOfTheProduct,
        string memory _notes,
        uint256 _price
    ) public onlySupplier lessThan20(_price) {
        uint256 _sku = sku.current();
        uint256 _upc = upc.current();
        uint256 productId = uint256(keccak256(abi.encodePacked(_sku, _upc)));
        // calculate the vat amount
        uint256 newVatForThePrice = calculatePercentage(_price);
        Product memory proudct = Product({
            sku: _sku,
            upc: _upc,
            productId: productId,
            vat: newVatForThePrice,
            vatToCollect: newVatForThePrice,
            state: State.Created,
            nameOfTheProduct: _nameOfTheProduct,
            productNotes: _notes,
            productPrice: _price,
            ownerAddress: _msgSender(),
            supplierAddress: _msgSender(),
            distributorAddress: _msgSender(),
            traderAddress: _msgSender(),
            consumerAddress: _msgSender()
        });
        // record in mappings
        skuToProduct[_sku] = proudct;
        upcToProduct[_upc] = proudct;

        paidVat[_sku] = newVatForThePrice;
        uint256 _paidVat = paidVat[_sku];
        // increments
        sku.increment();
        upc.increment();
        emit ProductCreated(_sku, _price, _msgSender(), _paidVat);
    }

    function shipProudct(uint256 _sku, uint256 _price)
        public
        onlyDistributor
        created(_sku)
    {
        uint256 _paidVat = paidVat[_sku];
        uint256 newVatForThePrice = calculatePercentage(_price);
        Product memory product = skuToProduct[_sku];
        product.state = State.Distributed;
        product.productPrice = _price;
        product.vatToCollect = newVatForThePrice - _paidVat;
        product.vat = newVatForThePrice;
        product.distributorAddress = _msgSender();
        product.ownerAddress = _msgSender();

        skuToProduct[_sku] = product;
        paidVat[_sku] = newVatForThePrice;
        emit ProductDistributed(_sku, _price, _msgSender(), newVatForThePrice);
    }

    function deliverToTrader(uint256 _sku, uint256 _price)
        public
        onlyTrader
        distributed(_sku)
    {
        // bring the info
        uint256 _paidVat = paidVat[_sku];
        uint256 newVatForThePrice = calculatePercentage(_price);
        Product memory product = skuToProduct[_sku];
        // update the fields
        product.productPrice = _price;
        product.ownerAddress = _msgSender();
        product.traderAddress = _msgSender();
        product.vat = newVatForThePrice;
        product.vatToCollect = newVatForThePrice - _paidVat;
        product.state = State.Traded;
        // update the product mapping
        skuToProduct[_sku] = product;
        // update the collected VAT
        paidVat[_sku] = newVatForThePrice;
        // emit the event
        emit ProductedInStore(_sku, _price, _msgSender(), _paidVat);
    }

    function sellProduct(uint256 _sku, uint256 _price) public traded(_sku) {
        // bring the info
        uint256 _paidVat = paidVat[_sku];
        uint256 newVatForThePrice = calculatePercentage(_price);
        Product memory product = skuToProduct[_sku];
        // update the fields
        product.productPrice = _price;
        product.ownerAddress = _msgSender();
        product.consumerAddress = _msgSender();
        product.vat = newVatForThePrice;
        product.vatToCollect = newVatForThePrice - _paidVat;

        // update the product mapping
        skuToProduct[_sku] = product;

        // update the vat
        paidVat[_sku] = newVatForThePrice;
        emit ProductedSold(_sku, _price, _msgSender(), _paidVat);
    }

    function getVatPaid(uint256 _sku) public view returns (uint256) {
        return paidVat[_sku];
    }

    function getProductSku(uint256 _sku) public view returns (Product memory) {
        return skuToProduct[_sku];
    }

    function getProductUpc(uint256 _upc) public view returns (Product memory) {
        return upcToProduct[_upc];
    }

    function fetchProduct(uint256 _sku)
        public
        view
        returns (
            uint256 productSKU,
            uint256 productUPC,
            address productOwner,
            State productState,
            uint256 vat
        )
    {
        Product memory product = skuToProduct[_sku];

        return (
            product.sku,
            product.upc,
            product.ownerAddress,
            product.state,
            product.vatToCollect
        );
    }

    function calculatePercentage(uint256 _price)
        internal
        pure
        returns (uint256)
    {
        return (_price * VAT_PERCENTAGE) / 100;
    }
}
