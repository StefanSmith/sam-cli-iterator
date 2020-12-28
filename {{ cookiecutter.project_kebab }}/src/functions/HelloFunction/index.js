import {hello} from "../../domain/greetings";
import {additionalGreeting} from "./additionalGreeting";

export const handler = async () => ({
    statusCode: 200,
    body: `${hello()} ${additionalGreeting()}`,
    headers: {'Content-Type': 'text/plain'}
});