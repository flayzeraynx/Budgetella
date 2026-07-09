A transaction or category row: category badge, title + subtitle, optional amount. Press tints the row brand-violet.

```jsx
<ListRow category="shopping" title="Migros" subtitle="Shopping · 14:30" amount="1.240" sign="expense" />
<ListRow category="income" title="Freelance" subtitle="6 May" amount="12.000" sign="income" />
```

Pass `trailing` for a custom right side (e.g. a chevron) instead of an amount.
