# LuxFHE Hardhat Example [![Open in Gitpod][gitpod-badge]][gitpod]

[gitpod]: https://gitpod.io/#https://github.com/luxfheprotocol/luxfhe-hardhat-example
[gitpod-badge]: https://img.shields.io/badge/Gitpod-Open%20in%20Gitpod-FFB45B?logo=gitpod

This repository contains a sample project that you can use as the starting point
for your LuxFHE project. It's also a great fit for learning the basics of
LuxFHE smart contract development.

This project is intended to be used with the
[LuxFHE Hardhat Beginners Tutorial](TODO), but you should be
able to follow it by yourself by reading the README and exploring its
`contracts`, `tests`, `deploy` and `tasks` directories.

It comes with two luxfhe-specific hardhat plugins:

- `luxfhe-hardhat-plugin`: The main plugin for luxfhe development in hardhat. It injects `luxfhejs` into the hardhat runtime environment, which allows you to interact with encrypted data in your tests and tasks.
- `luxfhe-hardhat-docker`: A plugin that allows you to run a local LuxFHE testnet in a docker container. This is useful for testing your contracts in a sandbox before deploying them on a testnet or on mainnet.

## Quick start

The first things you need to do are cloning this repository and installing its dependencies:

```sh
git clone https://github.com/LuxFHEProtocol/luxfhe-hardhat-example.git
cd luxfhe-hardhat-example
pnpm install
```

Once installed, let's run a LocalLuxFHE instance:

```sh
pnpm localluxfhe:start
```

This will start a LocalLuxFHE instance in a docker container. If this worked you should see a `Started LocalLuxFHE successfully` message in your console.

If not, please make sure you have `docker` installed and running on your machine. You can find instructions on how to install docker [here](https://docs.docker.com/get-docker/).

Now that we have a LocalLuxFHE instance running, we can deploy our contracts to it:

```sh
npx hardhat deploy
```

Note that this template defaults to use the `localluxfhe` network, which is injected into the hardhat configuration.

Finally, we can run the tasks with:

```sh
pnpm task:getCount # => 0
pnpm task:addCount
pnpm task:getCount # => 1
pnpm task:addCount --amount 5
pnpm task:getCount # => 6
```

TODO: frontend

## More Info

To learn more about the LuxFHE Hardhat plugin, check out the [LuxFHE Hardhat Plugin Repository](https://github.com/LuxFHEProtocol/luxfhe-hardhat-plugin).
