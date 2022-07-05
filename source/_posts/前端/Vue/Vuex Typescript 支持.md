---
title: Vuex Typescript 支持
tags:
  - Vue
  - Vuex
categories:
  - 前端
  - Vue
date: 2022-07-05 18:03:13
---

# 1. 定义

## 1.1 定义入口模块

入口 `/src/store/index.ts` :

```ts
import type {InjectionKey} from 'vue';
import {createStore, Store, useStore as baseUseStore} from 'vuex';
// 引入子模块
import createUserState, {IUserState} from './user';

export interface IRootState {}

export interface IModuleState {
    user: IUserState;
	// other modules
}

export const storeInjectionKey: InjectionKey<Store<IRootState & IModuleState>> = Symbol('storeInjectionKey');

export default function initStore() {
    return createStore<IRootState>({
        state: {},
        mutations: {},
        actions: {},
        modules: {
            user: createUserState(),
			// other modules
        },
    });
}

// 定义自己的 `useStore` 组合式函数
export function useStore() {
    return baseUseStore(storeInjectionKey);
}
```

## 1.2 定义子模块

User 模块 `/src/store/user.ts` :

```ts
import type {InjectionKey} from 'vue';
import {Store} from 'vuex';
import type {Module} from 'vuex';
import {IRootState} from '.';
import {getUserDetail, getUserStatus} from '@/base/api/user';
import {IS_NODE} from '@/base/utils';

export interface IUserDetail {
    id?: number;
    ucid?: string;
    unfinished_orders_num?: number;
    orders_num?: number;
    has_saas?: boolean;
}

// 定义 UserState 的接口
export interface IUserState {
    isLogin: boolean;
    ucid?: string;
    ucname?: string;
    loginType?: 'uc';
    detail?: IUserDetail;
}

// 可选
export const storeUserKey: InjectionKey<Store<IUserState>> = Symbol('storeUserKey');

// 导出一个创建 State Module 的方法，防止在 SSR 场景下每个请求都使用同一个实例
function createUserState(): Module<IUserState, IRootState> {
    namespaced: true,
    state: () => ({
        isLogin: false,
    }),
    mutations: {
        setLoginStatus(state, payload) {
            state.isLogin = payload.isLogin;
            state.loginType = payload.loginType;
        },
        setLoginInfo(state, payload) {
            state.ucid = payload.ucid;
            state.ucname = payload.ucname;
        },
        setUserDetail(state, payload) {
            state.detail = payload;
        },
        setLoginOut(state) {
            state.isLogin = false;
        },
    },
    actions: {
        getUserStatus: async (store, payload) => {
            // do somethings
        },
        getUserDetail: async (store, payload) => {
            // do somethings
        },
    },
    getters: {},
};

export default createUserState
```

# 2. 使用

```ts
import {computed} from 'vue'
import {useStore} from '/src/store';

const {state, dispatch} = useStore();

const ucid = computed(state => state.user?.ucid)
dispatch('user/getUserStatus');
```