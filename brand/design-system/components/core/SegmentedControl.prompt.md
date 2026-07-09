Pill segmented toggle for 2–3 options (Expense/Income, All/Income/Expense).

```jsx
<SegmentedControl options={['Expense','Income']} value={v} onChange={setV} tone="expense" />
<SegmentedControl options={[{value:'all',label:'All'},{value:'in',label:'Income'}]} value={v} onChange={setV} />
```

`tone` colors the active pill: accent (default) · expense · income.
