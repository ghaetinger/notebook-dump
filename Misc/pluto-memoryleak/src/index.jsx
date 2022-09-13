import { React, ReactDOM } from './deps.ts';

/**
 * 
 * @param {HTMLSpanElement} element
 * @returns {React.ReactElement}
 */
function TestFoo({
    element
}) {
    const [value, setValue] = React.useState(0);
    const [secondValue, setSecondValue] = React.useState(0);

    const update_span = () => {
        element.value = value * secondValue;
        element.dispatchEvent(new CustomEvent('input'));
    }

    // Initializes element value
    React.useEffect(() => {
        element.value = 0;
        update_span();
    }, [])

    const when_update_value = () => {
        setSecondValue(secondValue + 1)
        console.log('💧', value);
        update_span();
    };

    const when_update_second_value = () => {
        console.log('💧', secondValue);
        update_span();
    };

    React.useEffect(when_update_value, [value]);
    React.useEffect(when_update_second_value, [secondValue]);

    return (
        <div>
            <b>First Value: {value}</b>
            <br></br>
            <b>Second Value: {secondValue}</b>
            <br></br>
            <button onClick={() => setValue(value + 1)}>+</button>
        </div>
    )
}

function render(target) {
    ReactDOM.render(<TestFoo element={target} />, target);
}

export { render }
