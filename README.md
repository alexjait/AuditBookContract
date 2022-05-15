# AuditBookContract
Audit Book smart contract

This contract includes three actors: the administrator, the auditing company and the auditable company.

The administrator approves or rejects auditing and auditable companies.

Auditing companies can send findings to auditable companies.

Auditable companies can accept or reject the finding.

## hardhat.config.js

If you use "npx hardhat node", change these lines:

localhost: {

      url: 'http://localhost:8545',
      
      accounts: ['HERE THE ACCOUNT PRIVATE KEY'],
      
}

## .env

If you use Alchemy, complete these configuration with url and key from Alchemy:

ALCHEMY_RINKEBY_URL=

RINKEBY_PRIVATE_KEY=

## Compile and Deploy

### localhost
npx hardhat compile

npx hardhat console --network localhost

### Rinkeby
npx hardhat compile

npx hardhat console --network rinkeby



