import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    vus: 500,
    duration: '10s',
};

export default function () {
    const url = 'http://nawatech:80/api/v1/orders/checkout';

    const randomUserId = Math.floor(Math.random() * 1000) + 1;

    const payload = JSON.stringify({
        user_id: randomUserId,
        items: [
            {
                product_id: 1,
                quantity: 1,
            }
        ],
    });

    const params = {
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        },
    };

    const res = http.post(url, payload, params);

    check(res, {
        'is status 200 or 400': (r) => r.status === 200 || r.status === 422
    });

    sleep(1);
}
