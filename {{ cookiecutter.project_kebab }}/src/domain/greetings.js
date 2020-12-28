import * as faker from 'faker';

const getName = () => faker.name.firstName('male');

export const hello = () => `Hello ${getName()}!`;

export const howdy = () => `Howdy ${getName()}!`;