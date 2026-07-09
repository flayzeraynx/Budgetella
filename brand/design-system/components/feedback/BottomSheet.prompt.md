Modal bottom sheet (28px sheet radius) with grabber handle + dimmed scrim. Render inside a `position:relative` phone-frame container.

```jsx
<div style={{position:'relative', height:640}}>
  <BottomSheet open={open} title="Add expense" onClose={close}>…</BottomSheet>
</div>
```
