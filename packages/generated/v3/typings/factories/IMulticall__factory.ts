/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type { IMulticall, IMulticallInterface } from "../IMulticall";

const _abi = [
  {
    type: "function",
    name: "multicall",
    inputs: [
      {
        name: "data",
        type: "bytes[]",
        internalType: "bytes[]",
      },
    ],
    outputs: [
      {
        name: "results",
        type: "bytes[]",
        internalType: "bytes[]",
      },
    ],
    stateMutability: "nonpayable",
  },
] as const;

export class IMulticall__factory {
  static readonly abi = _abi;
  static createInterface(): IMulticallInterface {
    return new utils.Interface(_abi) as IMulticallInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IMulticall {
    return new Contract(address, _abi, signerOrProvider) as IMulticall;
  }
}
