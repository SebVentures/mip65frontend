import scrapy
from urllib.parse import urlencode
from dateutil.parser import parse
import calendar
from web3 import Web3, EthereumTesterProvider
from web3.middleware import geth_poa_middleware
from dotenv import load_dotenv
import os

load_dotenv()

class EtfSpider(scrapy.Spider):
    name = 'etfspider'
    start_urls = ['https://www.ishares.com/uk/individual/en/products/307243/ishares-treasury-bond-0-1yr-ucits-etf?siteEntryPassthrough=true',
        'https://www.ishares.com/uk/individual/en/products/287340/ishares-treasury-bond-1-3yr-ucits-etf?siteEntryPassthrough=true']

    def parse(self, response):
        # legal blocker if any
        url = response.css("div.cta a")
        if url:
            return response.follow(url.attrib["href"], self.parse)

        print(response.css("p.identifier::text").get())
        data = dict()
        data['ticker'] = response.css("p.identifier::text").get().strip()
        date = response.css("span.header-nav-label::text").get().strip()
        date = date[10:]
        date = parse(date)
        print(date.timetuple())
        date = calendar.timegm(date.timetuple())
        data['date'] = int(date)
        nav = response.css("span.header-nav-data::text").get().strip()
        nav = float(nav[4:])
        data['nav'] = nav
        ytm = response.css("div.col-yieldToWorst span.data::text").get().strip()
        ytm = float(ytm[:-1])/100
        data['ytm'] = ytm
        print(date)

        # Sanity check to avoid putting garbage
        assert nav > 0.0, "nav should be positive"
        assert nav < 99999999999.0, "nav should be not too high"
        assert ytm > -3.0, "ytm shouldn't be too negative"
        assert ytm < 1000.0, "ytm shouldn't be too high"
        assert date % (3600*24) == 0, "date should be a day without hours/minutes"

        print(data)

        self.poke(data)


    def poke(self, data): 
        # Configure w3, e.g., w3 = Web3(...)
        w3 = Web3(Web3.HTTPProvider(os.environ.get('WEB3_HTTP_PROVIDER')))
        w3.middleware_onion.inject(geth_poa_middleware, layer=0)
        mip65tracker_address = os.environ.get('MIP65TRACKER_ADDRESS')
        abi = '[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"asset","type":"string"},{"indexed":false,"internalType":"uint256","name":"ts","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"qty","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"price","type":"uint256"}],"name":"AssetBuy","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"asset","type":"string"},{"indexed":false,"internalType":"uint256","name":"price","type":"uint256"}],"name":"AssetInit","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"asset","type":"string"},{"indexed":false,"internalType":"uint256","name":"ts","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"qty","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"price","type":"uint256"}],"name":"AssetSell","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"asset","type":"string"},{"indexed":false,"internalType":"uint256","name":"ts","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"price","type":"uint256"}],"name":"AssetUpdate","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"role","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"previousAdminRole","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"newAdminRole","type":"bytes32"}],"name":"RoleAdminChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"role","type":"bytes32"},{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"sender","type":"address"}],"name":"RoleGranted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"role","type":"bytes32"},{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"address","name":"sender","type":"address"}],"name":"RoleRevoked","type":"event"},{"inputs":[],"name":"DEFAULT_ADMIN_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"OPS_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PRICE_ROLE","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"assets","outputs":[{"internalType":"string[]","name":"","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"},{"internalType":"uint256","name":"ts","type":"uint256"},{"internalType":"uint256","name":"qty","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"}],"name":"buy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"}],"name":"detail","outputs":[{"internalType":"uint256","name":"qty","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"}],"name":"getRoleAdmin","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"grantRole","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"hasRole","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"},{"internalType":"uint256","name":"price","type":"uint256"}],"name":"init","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"renounceRole","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"role","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"revokeRole","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"},{"internalType":"uint256","name":"ts","type":"uint256"},{"internalType":"uint256","name":"qty","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"}],"name":"sell","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"asset","type":"string"},{"internalType":"uint256","name":"ts","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"}],"name":"update","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"value","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]'
        mip65tracker = w3.eth.contract(address=mip65tracker_address, abi=abi)
        
        account = {
            "private_key": os.environ.get('PRIVATE_KEY'),
            "address": os.environ.get('ACCOUNT_ADDRESS'),
        }

        print(w3.eth.accounts)

        # read state:
        last_price = (mip65tracker.functions.detail(data['ticker']).call())[1]
        print(last_price)

        new_price = int(data['nav'] * 10**18)

        # Don't update if nothing new
        if last_price == new_price:
            return
        
        # If price different we make an update
        construct_tx = mip65tracker.functions.update(data['ticker'], data['date'], new_price).buildTransaction(
            {'from':account['address'], 'nonce': w3.eth.get_transaction_count(account['address'])})
        
        # Sign tx
        tx_create = w3.eth.account.sign_transaction(construct_tx, account['private_key'])

        # 7. Send tx and wait for receipt
        tx_hash = w3.eth.send_raw_transaction(tx_create.rawTransaction)
        tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

        print(tx_hash)
