# Analysis Report: Interactive Controls, State Management & Event Handlers in Parking Lot Management

**Survey Date**: 2026-11-04  
**Target Module**: `parking_management_frontend/src/pages/ParkingLotManagement.jsx` and its sub-components  
**Author**: Explorer Subagent 3 (`teamwork_explorer_survey_3`)  
**Parent Orchestrator ID**: `56b281bd-5651-4f01-b1aa-31010383d653`

---

## 1. Executive Summary

This investigation analyzes the interactive controls, state management, and event handlers on the Parking Lot Management page (`ParkingLotManagement.jsx`) and its sub-components (`ParkingLotFilters`, `ParkingSlotMatrix`, `SlotDetailPanel`, `ParkingLotStatsCards`, `ParkingLotStructureAndActivity`).

### Core Findings
1. **Disconnected Filter State**: Filter states (`selectedFloor`, `selectedZone`) exist in `ParkingLotManagement.jsx` (lines 14–15), but `currentZoneData` is hardcoded to `fullParkingLotData[0]?.zones[0]` (line 21) with an empty dependency array. Changing floor or zone in dropdowns has **zero effect** on displayed slots. The "Reset filters" button only resets 3 search/status fields and ignores floor/zone.
2. **Missing List View**: There is **no List View implemented or even stubbed**. There is no `viewMode` state, no Matrix/List toggle button, and no table component rendered for slot listing.
3. **Shallow/Stub Actions in `SlotDetailPanel`**:
   - "✏️ Sửa" (Edit) and "🗑️ Xóa" (Delete) buttons have **no `onClick` handlers** (lines 107–123).
   - "Cập nhật nhanh trạng thái" buttons (lines 132–185) mutate only the local `selectedSlot` state. They **do not update** `allSlots`, the slot matrix display, or `stats`. The matrix cards remain stuck in their original mock state.
4. **Header and Structure Buttons are Stubs**: PageHeader buttons ("Xuất báo cáo", "+ Thêm tầng", "+ Thêm khu", "+ Thêm ô đỗ xe") and Structure card buttons ("⚙ Cấu hình", "Sửa", "Xóa") have **no `onClick` handlers**.
5. **Selection Highlight Bug**: In `ParkingSlotMatrix.jsx` (line 77), `MAINTENANCE` slots lack the `isSelected` ring styling that `AVAILABLE`, `OCCUPIED`, and `RESERVED` have.

---

## 2. Detailed Findings by Survey Questions

### Question 1: How is filter state currently managed in `ParkingLotManagement` and `ParkingLotFilters`? Does the reset button work?

#### Implementation Analysis:
- In `ParkingLotManagement.jsx` (lines 14–18):
  ```javascript
  const [selectedFloor, setSelectedFloor] = useState("B1");
  const [selectedZone, setSelectedZone] = useState("A");
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [vehicleTypeFilter, setVehicleTypeFilter] = useState("");
  ```
- **Disconnection Defect** (lines 20–26):
  ```javascript
  const currentZoneData = useMemo(() => {
    return fullParkingLotData[0]?.zones[0];
  }, []); // Empty dependency array, ignores selectedFloor & selectedZone!

  const allSlots = useMemo(() => {
    return currentZoneData?.slots || [];
  }, [currentZoneData]);
  ```
  `currentZoneData` statically returns `fullParkingLotData[0]?.zones[0]` (Tầng B1 - Khu A). When the user selects Floor "B2" or "F1", or Zone "B" or "C", the slot data remains unchanged.
- **Filter Matching Logic** (lines 56–71):
  ```javascript
  const matchesFilter = (slot) => {
    if (searchQuery.trim()) {
      const q = searchQuery.trim().toLowerCase();
      const matchLabel = slot.label?.toLowerCase().includes(q);
      const matchPlate = slot.plate?.toLowerCase().includes(q);
      if (!matchLabel && !matchPlate) return false;
    }
    if (statusFilter && slot.status !== statusFilter) return false;
    if (vehicleTypeFilter) {
      if (vehicleTypeFilter === "PRIORITY" && slot.type !== "PRIORITY") return false;
      if (vehicleTypeFilter === "STANDARD" && slot.type !== "STANDARD") return false;
    }
    return true;
  };
  ```
  In `ParkingSlotMatrix.jsx` (lines 4, 139, 172), `matchesFilter(slot)` sets `opacityClass = isMatch ? "opacity-100" : "opacity-30"`. Non-matching slots are dimmed rather than filtered out of the 2D grid.
- **Reset Button Behavior**:
  - In `ParkingLotFilters.jsx` (line 26):
    `const hasActiveFilters = Boolean(searchQuery || statusFilter || vehicleTypeFilter);`
  - Lines 91–108: Button "Đặt lại bộ lọc" only renders when `hasActiveFilters` is true.
  - In `ParkingLotManagement.jsx` (lines 81–85):
    ```javascript
    const handleResetFilters = () => {
      setSearchQuery("");
      setStatusFilter("");
      setVehicleTypeFilter("");
    };
    ```
  - **Verdict on Reset Button**: It works partially for the 3 fields (`searchQuery`, `statusFilter`, `vehicleTypeFilter`), but:
    1. It does not reset `selectedFloor` (to "B1") or `selectedZone` (to "A").
    2. Changing `selectedFloor` or `selectedZone` does not activate the reset button.
    3. The "Bãi đỗ xe" FilterSelect in `ParkingLotFilters.jsx` (line 34) has `onChange={() => {}}` (non-functional stub).

---

### Question 2: How is view mode (Matrix view vs List view) currently implemented? Is List view implemented or stubbed?

#### Implementation Analysis:
- **Matrix View**: Implemented in `ParkingSlotMatrix.jsx` as a 2D layout with hardcoded Row A and Row B slots on a dark background canvas (`#0B132B`).
- **List View**: **Completely missing**.
  - `ParkingLotManagement.jsx` has no `viewMode` state.
  - Neither `ParkingLotFilters.jsx` nor `PageHeader` has a view switcher (tabs/toggle button group).
  - There is no component rendering a table or list of slots.
  - (Note: `ParkingLotFilters.jsx` lines 111–125 has a button named "Chế độ chỉnh sửa sơ đồ", but it has no `onClick` and does not toggle views).
- **Requirement Alignment**:
  - Acceptance Criterion R3 explicitly requires: *"chuyển đổi chế độ xem (Matrix/List view)"* and *"Các bộ lọc, nút reset và chuyển đổi chế độ xem lọc và cập nhật danh sách/ma trận ô đỗ chính xác theo điều kiện chọn"*.
  - A view mode switcher (`viewMode: "matrix" | "list"`) must be added, and when `viewMode === "list"`, a `DataTable` component should display slots with columns: `Mã ô`, `Tầng/Khu`, `Loại ô`, `Biển số xe`, `Trạng thái`, `Thời gian đỗ / Đặt trước`, `Ghi chú`, `Hành động`.

---

### Question 3: How are slot clicks and slot selection handled? What actions are present in `SlotDetailPanel`? Are they wired up or non-functional stubs?

#### 1. Slot Clicks & Selection:
- Handled via `handleSelectSlot` in `ParkingLotManagement.jsx` (lines 88–108) passed as `onSelectSlot` to `ParkingSlotMatrix.jsx`.
- In `ParkingSlotMatrix.jsx`, clicking a slot card triggers `onSelect(slot)`.
- **Initial State Discrepancy**:
  In `ParkingLotManagement.jsx` (lines 29–40), `selectedSlot` is initially hardcoded to:
  `{ id: "A-01", status: "OCCUPIED", statusText: "Đang đỗ", licensePlate: "30A-123.45", ... }`.
  However, in `fullParkingLotData[0].zones[0].slots[0]`, slot `A-01` is actually `status: "AVAILABLE"` with `plate: null`. This creates an immediate visual contradiction on page load.
- **Selection Style Bug**:
  In `ParkingSlotMatrix.jsx`:
  - `AVAILABLE` (line 13–16): gets `ring-2 ring-emerald-400/50` when `isSelected`.
  - `OCCUPIED` (line 34–37): gets `ring-2 ring-rose-400/50` when `isSelected`.
  - `RESERVED` (line 58–61): gets `ring-2 ring-amber-400/50` when `isSelected`.
  - `MAINTENANCE` (line 77): lacks any conditional ring or highlight for `isSelected`.

#### 2. Actions in `SlotDetailPanel.jsx`:
- **"✏️ Sửa" (Edit slot)** (lines 107–114):
  ```jsx
  <Button variant="primary" size="sm" fullWidth className="cursor-pointer">
    ✏️ Sửa
  </Button>
  ```
  -> **Non-functional stub**. No `onClick` handler, no edit modal.
- **"🗑️ Xóa" (Delete slot)** (lines 115–122):
  ```jsx
  <Button variant="dangerOutline" size="sm" fullWidth className="cursor-pointer">
    🗑️ Xóa
  </Button>
  ```
  -> **Non-functional stub**. No `onClick` handler, no confirmation modal.
- **Quick Status Updates ("Cập nhật nhanh trạng thái")** (lines 132–185):
  - Buttons: "Đặt làm ô trống", "Đánh dấu có xe đỗ", "Đánh dấu đã đặt trước", "Đánh dấu bảo trì".
  - Code:
    ```javascript
    onClick={() =>
      setSelectedSlot((prev) => ({
        ...prev,
        status: "AVAILABLE",
        statusText: "Trống",
        licensePlate: "—",
      }))
    }
    ```
  - **Critical Defect**: This updates **only** `selectedSlot` state inside `SlotDetailPanel`. It **does not update** the master slots array in `ParkingLotManagement.jsx`!
  - Consequently:
    - The slot color/icon on the Matrix **remains unchanged**.
    - Stat cards (`stats.total`, `stats.available`, `stats.occupied`, `stats.reservedOrMaint`) **remain unchanged**.
    - Occupancy density percentage **remains unchanged**.
    - If the user clicks another slot and clicks back, the change is lost.
    - No toast feedback or persistence occurs.

---

### Question 4: What callbacks, state props, or mutation handlers need to be added or hooked up to make all buttons responsive and functional?

To achieve full interactive functionality without code duplication and conforming to modular clean code rules, the following handlers and state props must be implemented:

| Component | Control / Button | Current State | Required Callback / Handler | Expected Behavior |
|---|---|---|---|---|
| `ParkingLotManagement` | PageHeader `Xuất báo cáo` | No `onClick` | `handleExportReport` | Generates/downloads CSV of current floor/zone slots or displays toast notification. |
| `ParkingLotManagement` | PageHeader `+ Thêm tầng` | No `onClick` | `handleOpenAddFloorModal` | Opens modal to create a new floor with code, name, sort order. |
| `ParkingLotManagement` | PageHeader `+ Thêm khu` | No `onClick` | `handleOpenAddZoneModal` | Opens modal to create a new zone under selected floor. |
| `ParkingLotManagement` | PageHeader `+ Thêm ô đỗ xe` | No `onClick` | `handleOpenAddSlotModal` | Opens modal to add slot (slot code, row, column, kind, status). |
| `ParkingLotFilters` | `Bãi đỗ xe` Select | `onChange={() => {}}` | `setSelectedLot` | Supports changing lot if multi-lot exists. |
| `ParkingLotFilters` | `Tầng` / `Khu vực` Select | State updates, but data ignored | Connect to dynamic floor/zone resolver | Dynamically updates `currentZoneData` and `allSlots` based on `selectedFloor` and `selectedZone`. |
| `ParkingLotFilters` | `Đặt lại bộ lọc` Button | Resets only 3 fields | `handleResetFilters` | Resets all active filters including resetting floor/zone to defaults (`B1` / `A`). |
| `ParkingLotFilters` | `Chế độ chỉnh sửa sơ đồ` | No `onClick` | `handleToggleEditMode` | Toggles map layout editing mode / displays informative toast. |
| `ParkingLotFilters` / Toolbar | **View Mode Toggle** (New) | **Not implemented** | `viewMode`, `setViewMode` | Segmented toggle `[Ma trận ▦]` and `[Danh sách ☰]` to switch between matrix canvas and list table. |
| `SlotDetailPanel` | `✏️ Sửa` (Edit slot) | No `onClick` | `onEditSlot(slot)` | Opens `EditSlotModal` to update slot type, plate, note, or reserved time. |
| `SlotDetailPanel` | `🗑️ Xóa` (Delete slot) | No `onClick` | `onDeleteSlot(slot)` | Opens `ConfirmModal` to confirm slot removal or deactivation. |
| `SlotDetailPanel` | 4 Quick status buttons | Updates only local `selectedSlot` | `onUpdateSlotStatus(slotId, newStatus, extraData)` | Parent mutates slot in `allSlots`, updates `selectedSlot`, recomputes `stats`, and shows `toast.success`. |
| `ParkingLotStructureAndActivity` | `⚙ Cấu hình` Button | No `onClick` | `onOpenConfigModal` | Opens configuration modal for structure management or shows toast. |
| `ParkingLotStructureAndActivity` | Item `Sửa` Button | No `onClick` | `onEditStructure(item)` | Opens modal to rename or edit floor/zone details. |
| `ParkingLotStructureAndActivity` | Item `Xóa` Button | No `onClick` | `onDeleteStructure(item)` | Prompts with `ConfirmModal` before soft-deleting structure element. |

---

## 3. Recommended State Architecture for Frontend

### State Hierarchy in `ParkingLotManagement.jsx`
```
ParkingLotManagement (State Container)
  │
  ├── State:
  │   ├── selectedFloor: "B1"
  │   ├── selectedZone: "A"
  │   ├── searchQuery: ""
  │   ├── statusFilter: ""
  │   ├── vehicleTypeFilter: ""
  │   ├── viewMode: "matrix" | "list"
  │   ├── slotsData: Slot[] (Mutable master list loaded from API/service or initial mock)
  │   ├── selectedSlot: Slot | null
  │   ├── isEditModalOpen, isAddSlotModalOpen, deleteConfirmState, ...
  │
  ├── Computed (useMemo):
  │   ├── filteredSlots: slotsData matching floor, zone, search, status, type
  │   ├── stats: { total, available, occupied, reservedOrMaint, densityPercent }
  │   ├── rowASlots, rowBSlots, rowCSlots (or dynamic rows)
  │
  └── Handlers:
      ├── handleSelectSlot(slot)
      ├── handleUpdateSlotStatus(slotId, newStatus, extraData)
      ├── handleSaveSlot(updatedSlot)
      ├── handleDeleteSlot(slotId)
      ├── handleResetFilters()
      └── handleExportSlotsCsv()
```

---

## 4. ESLint and Build Hygiene

When running `npm run lint` inside `parking_management_frontend`:
1. `import React from "react"` in `ParkingLotFilters.jsx`, `ParkingLotStatsCards.jsx`, `ParkingLotStructureAndActivity.jsx`, `ParkingSlotMatrix.jsx`, and `SlotDetailPanel.jsx` triggers `no-unused-vars` because Vite uses the automatic JSX runtime (`react/jsx-runtime`).
2. In `ParkingSlotMatrix.jsx`:
   Exporting `renderSlotCard` alongside `ParkingSlotMatrix` causes:
   `Fast refresh only works when a file only exports components (react-refresh/only-export-components)`.
   *Remedy*: Move `renderSlotCard` into its own component file (e.g. `ParkingSlotCard.jsx`) or unexport it.
