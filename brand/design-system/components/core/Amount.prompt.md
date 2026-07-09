Currency amount with tabular/monospaced digits so figures never jitter. Semantic coloring.

```jsx
<Amount value="245.847" sign="income" showSign />
<Amount value="73.000" sign="expense" size="body" showSign />
<Amount value="500" currency="$" sign="neutral" />
```

`sign`: income (mint) · expense (coral) · neutral. `size`: hero · title · body · callout. `showSign` prefixes + / −.
