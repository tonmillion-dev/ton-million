import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/ton_million_tonball.tact',
    options: {
        debug: true,
    },
};
