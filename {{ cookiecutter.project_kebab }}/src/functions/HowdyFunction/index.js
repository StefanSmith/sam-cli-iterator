import {howdy} from "../../domain/greetings";

export const handler = async () => ({statusCode: 200, body: howdy(), headers: {'Content-Type': 'text/plain'}});