import { React, ReactDOM } from './deps.ts';

function TestFoo({
    element
}) {
    const [value, setValue] = useState(0);

    const when_update_element = () => {
	console.log('💧', value, i);
    };

    React.useEffect(when_update_element, [value]);

    return (
        <div>
            <b>{value}</b>
            <button onClick={() => setValue(value + 1)}>+</button>
        </div>
    )
}

function render(target) {
    ReactDOM.render(<TestFoo element={target}/>, target);
}

export { render }
