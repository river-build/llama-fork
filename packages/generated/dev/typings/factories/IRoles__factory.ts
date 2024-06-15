/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type { IRoles, IRolesInterface } from "../IRoles";

const _abi = [
  {
    type: "function",
    name: "addPermissionsToRole",
    inputs: [
      {
        name: "roleId",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "permissions",
        type: "string[]",
        internalType: "string[]",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "addRoleToEntitlement",
    inputs: [
      {
        name: "roleId",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "entitlement",
        type: "tuple",
        internalType: "struct IRolesBase.CreateEntitlement",
        components: [
          {
            name: "module",
            type: "address",
            internalType: "contract IEntitlement",
          },
          {
            name: "data",
            type: "bytes",
            internalType: "bytes",
          },
        ],
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "createRole",
    inputs: [
      {
        name: "roleName",
        type: "string",
        internalType: "string",
      },
      {
        name: "permissions",
        type: "string[]",
        internalType: "string[]",
      },
      {
        name: "entitlements",
        type: "tuple[]",
        internalType: "struct IRolesBase.CreateEntitlement[]",
        components: [
          {
            name: "module",
            type: "address",
            internalType: "contract IEntitlement",
          },
          {
            name: "data",
            type: "bytes",
            internalType: "bytes",
          },
        ],
      },
    ],
    outputs: [
      {
        name: "roleId",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "getPermissionsByRoleId",
    inputs: [
      {
        name: "roleId",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "permissions",
        type: "string[]",
        internalType: "string[]",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getRoleById",
    inputs: [
      {
        name: "roleId",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "role",
        type: "tuple",
        internalType: "struct IRolesBase.Role",
        components: [
          {
            name: "id",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "name",
            type: "string",
            internalType: "string",
          },
          {
            name: "disabled",
            type: "bool",
            internalType: "bool",
          },
          {
            name: "permissions",
            type: "string[]",
            internalType: "string[]",
          },
          {
            name: "entitlements",
            type: "address[]",
            internalType: "contract IEntitlement[]",
          },
        ],
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getRoles",
    inputs: [],
    outputs: [
      {
        name: "roles",
        type: "tuple[]",
        internalType: "struct IRolesBase.Role[]",
        components: [
          {
            name: "id",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "name",
            type: "string",
            internalType: "string",
          },
          {
            name: "disabled",
            type: "bool",
            internalType: "bool",
          },
          {
            name: "permissions",
            type: "string[]",
            internalType: "string[]",
          },
          {
            name: "entitlements",
            type: "address[]",
            internalType: "contract IEntitlement[]",
          },
        ],
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "removePermissionsFromRole",
    inputs: [
      {
        name: "roleId",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "permissions",
        type: "string[]",
        internalType: "string[]",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "removeRole",
    inputs: [
      {
        name: "roleId",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "removeRoleFromEntitlement",
    inputs: [
      {
        name: "roleId",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "entitlement",
        type: "tuple",
        internalType: "struct IRolesBase.CreateEntitlement",
        components: [
          {
            name: "module",
            type: "address",
            internalType: "contract IEntitlement",
          },
          {
            name: "data",
            type: "bytes",
            internalType: "bytes",
          },
        ],
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "updateRole",
    inputs: [
      {
        name: "roleId",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "roleName",
        type: "string",
        internalType: "string",
      },
      {
        name: "permissions",
        type: "string[]",
        internalType: "string[]",
      },
      {
        name: "entitlements",
        type: "tuple[]",
        internalType: "struct IRolesBase.CreateEntitlement[]",
        components: [
          {
            name: "module",
            type: "address",
            internalType: "contract IEntitlement",
          },
          {
            name: "data",
            type: "bytes",
            internalType: "bytes",
          },
        ],
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "event",
    name: "RoleCreated",
    inputs: [
      {
        name: "creator",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "roleId",
        type: "uint256",
        indexed: true,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RoleRemoved",
    inputs: [
      {
        name: "remover",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "roleId",
        type: "uint256",
        indexed: true,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RoleUpdated",
    inputs: [
      {
        name: "updater",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "roleId",
        type: "uint256",
        indexed: true,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "error",
    name: "Roles__EntitlementAlreadyExists",
    inputs: [],
  },
  {
    type: "error",
    name: "Roles__EntitlementDoesNotExist",
    inputs: [],
  },
  {
    type: "error",
    name: "Roles__InvalidEntitlementAddress",
    inputs: [],
  },
  {
    type: "error",
    name: "Roles__InvalidPermission",
    inputs: [],
  },
  {
    type: "error",
    name: "Roles__PermissionAlreadyExists",
    inputs: [],
  },
  {
    type: "error",
    name: "Roles__PermissionDoesNotExist",
    inputs: [],
  },
  {
    type: "error",
    name: "Roles__RoleDoesNotExist",
    inputs: [],
  },
] as const;

export class IRoles__factory {
  static readonly abi = _abi;
  static createInterface(): IRolesInterface {
    return new utils.Interface(_abi) as IRolesInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): IRoles {
    return new Contract(address, _abi, signerOrProvider) as IRoles;
  }
}
