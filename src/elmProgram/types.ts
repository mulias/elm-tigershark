/**
 * The type of an Elm 0.19 program which can be mounted by TypeScript.
 */
export type ElmProgram<Flags, Ports> = {
  init: (options: { flags: Flags }) => { ports: Ports };
};

/**
 * A helper type for extracting the shape of the ports object from an
 * Elm 0.19 app with a type declaration.
 */
export type Ports<T extends ElmProgram<any, any>> = T extends ElmProgram<any, infer P> ? P : never;

/**
 * A helper type for extracting the shape of the flags argument from an
 * Elm 0.19 app with a type declaration.
 */
export type Flags<T extends ElmProgram<any, any>> = T extends ElmProgram<infer F, any> ? F : never;
