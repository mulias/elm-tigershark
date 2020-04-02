type ElmApp<Flags, Ports> = {
  init: (options: { flags: Flags }) => { ports: Ports };
};

/**
 * A helper type for extracting the shape of the ports object from an
 * Elm 0.19 app with a type declaration.
 */
export type Ports<T extends ElmApp<any, any>> = T extends ElmApp<any, infer P>
  ? P
  : never;

/**
 * A helper type for extracting the shape of the flags argument from an
 * Elm 0.19 app with a type declaration.
 */
export type Flags<T extends ElmApp<any, any>> = T extends ElmApp<infer F, any>
  ? F
  : never;
