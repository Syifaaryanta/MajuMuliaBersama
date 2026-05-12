<template>
  <div class="gudang-page" ref="pageEl" tabindex="-1">

    <!-- -- PAGE HEADER ------------------------------------ -->
    <div class="g-header">
      <div class="g-header-left">
        <h1 class="g-title">Manajemen Data Produk</h1>
        <p class="g-subtitle">Kelola data produk, stok, harga, dan dokumentasi foto</p>
      </div>
      <button class="btn-tambah-header" @click="openAdd" title="Tambah Barang Baru (F2)">
        <i class="pi pi-plus"></i>
        <span class="btn-label">Tambah Baru</span>
        <kbd class="kbd-f2">F2</kbd>
      </button>
    </div>

    <!-- -- SEARCH BAR ------------------------------------- -->
    <div class="ktl-search-wrap">
      <div class="ktl-search-inner" :class="{ focused: isFocused }">
        <i class="pi pi-search ktl-search-icon"></i>
        <input
          ref="inputBarang"
          v-model="searchBarang"
          type="text"
          class="ktl-search-input"
          placeholder="Ketik nama atau kode barang, Enter untuk cari…"
          autocomplete="off"
          @focus="isFocused = true"
          @blur="isFocused = false"
          @keydown="onBarangKey"
        />
        <kbd class="ktl-hint-kbd">F1</kbd>
        <button
          v-if="searchBarang"
          class="ktl-clear-btn"
          @click="clearBarang"
          tabindex="-1"
        ><i class="pi pi-times"></i></button>
      </div>
    </div>

    <!-- -- EMPTY HINT ------------------------------------- -->
    <div v-if="!hasSearched" class="ktl-empty-hint">
      <div class="ktl-empty-icon-wrap">
        <i class="pi pi-search"></i>
      </div>
      <p class="ktl-empty-title">Cari barang untuk mulai mengelola</p>
      <p class="ktl-empty-sub">Ketik nama / kode lalu tekan <kbd>Enter</kbd> · Tambah barang baru dengan <kbd>F2</kbd></p>
    </div>

    <template v-else>
      <!-- Meta bar -->
      <div class="result-meta">
        <span class="result-count">
          <b>{{ totalRows }}</b> barang
          <span class="meta-kw">· "{{ lastSearch }}"</span>
        </span>
        <div class="ktl-meta-right">
          <template v-if="totalPages > 1">
            <button class="icon-btn" :disabled="currentPage <= 1" @click="prevPage">
              <i class="pi pi-chevron-left"></i>
            </button>
            <span class="page-indicator">{{ currentPage }}&nbsp;/&nbsp;{{ totalPages }}</span>
            <button class="icon-btn" :disabled="currentPage >= totalPages" @click="nextPage">
              <i class="pi pi-chevron-right"></i>
            </button>
          </template>
        </div>
      </div>


      <!-- Table -->
      <div class="table-wrap" ref="tableWrap">
        <table class="g-table ktl-table" ref="tableEl">
          <thead>
            <tr>
              <th class="col-no">#</th>
              <th class="col-kode">Kode</th>
              <th class="col-nama">Nama Barang</th>
              <th class="col-stok" style="text-align: center;">Stok Gudang</th>
              <th class="col-supplier" style="text-align: center;">Supplier (Stok)</th>
              <th class="col-harga" style="text-align: center;">Harga Beli</th>
            </tr>
          </thead>
          <tbody v-if="loading">
            <tr v-for="n in 5" :key="n">
              <td colspan="6"><div class="skeleton"></div></td>
            </tr>
          </tbody>
          <tbody v-else-if="pagedRows.length === 0">
            <tr>
              <td colspan="6" class="empty-cell">
                <i class="pi pi-search-minus"></i>
                Tidak ada barang ditemukan untuk "<b>{{ lastSearch }}</b>"
              </td>
            </tr>
          </tbody>
          <tbody v-else>
            <template v-for="(row, i) in pagedRows" :key="row.product_id">
              <tr
                v-for="(price, priceIdx) in (row.prices.length ? row.prices : [{ id: `empty-${row.product_id}`, stok: null, supplier_nama: '-', harga_beli: null }])"
                :key="`${row.product_id}-${price.id}`"
                :ref="el => { if (priceIdx === 0) setRowRef(el, i); }"
                :data-index="i"
                class="g-row"
                :class="{
                  'g-row--active': selectedRowIndex === i,
                  'g-row--lowstok': Number(row.stok || 0) <= 3,
                }"
                @click="onRowClick(row, i)"
                @dblclick="openEdit(row)"
              >
                <td v-if="priceIdx === 0" :rowspan="Math.max(1, row.prices.length)" class="col-no">
                  {{ (currentPage - 1) * PAGE_SIZE + i + 1 }}
                </td>
                <td v-if="priceIdx === 0" :rowspan="Math.max(1, row.prices.length)" class="col-kode">
                  <span class="kode-badge">{{ row.kode }}</span>
                </td>
                <td v-if="priceIdx === 0" :rowspan="Math.max(1, row.prices.length)" class="col-nama">
                  <span class="nama-text">{{ row.nama }}</span>
                  <span v-if="row.deskripsi" class="deskripsi-text">{{ row.deskripsi }}</span>
                </td>
                <td v-if="priceIdx === 0" :rowspan="Math.max(1, row.prices.length)" class="col-stok" style="text-align: center; vertical-align: middle;">
                  <span class="stok-val" :class="{ 'stok-low': Number(row.stok || 0) <= 3 }">
                    {{ Number(row.stok || 0) }} {{ row.satuan }}
                  </span>
                </td>
                <td class="col-supplier" style="text-align: center;">
                  <span class="supplier-chip">
                    {{ price.supplier_nama }}
                    <template v-if="price.stok != null"> · {{ Number(price.stok || 0) }} {{ row.satuan }}</template>
                  </span>
                </td>
                <td class="col-harga" style="text-align: center;">
                  <span class="harga-val">{{ price.harga_beli == null ? '-' : formatRp(price.harga_beli) }}</span>
                </td>

              </tr>
            </template>
          </tbody>
        </table>
      </div>

      <!-- Foto produk (di bawah tabel, jika ada foto) -->
      <div
        v-if="selectedRowData?.foto_urls?.length > 0"
        class="product-photos"
        tabindex="0"
        ref="photoViewRef"
        @keydown.f1.prevent="openPhotoLightbox(0)"
      >
        <div class="photos-header">
          <span class="photos-title"><i class="pi pi-images"></i> Foto Produk</span>
          <span class="photos-count">{{ selectedRowData.foto_urls.length }} foto · <kbd>F1</kbd> fullscreen</span>
        </div>
        <div class="photos-grid" :class="`photos-grid--${selectedRowData.foto_urls.length}`">
          <div
            v-for="(url, idx) in selectedRowData.foto_urls"
            :key="url"
            class="photo-item"
            @click="openPhotoLightbox(idx)"
          >
            <img :src="url" :alt="`Foto ${idx + 1}`" class="photo-img" />
            <div class="photo-overlay"><i class="pi pi-search-plus"></i></div>
          </div>
        </div>
      </div>
    </template>

    <!-- ---------------------------------------------------
         MODAL PILIH MODE EDIT (ENTER PADA ROW)
    ---------------------------------------------------- -->
    <Teleport to="body">
      <Transition name="modal">
        <div
          v-if="editModeModal.show"
          class="modal-overlay"
          @keydown="onEditModeModalKeydown"
          @click.self="closeEditModeModal"
        >
          <div class="modal-box modal-box--choice" role="dialog" aria-label="Pilih mode edit" ref="editModeModalRef" tabindex="0">
            <div class="modal-header modal-header--blue modal-header--center">
              <h3 class="modal-title">Pilih Mode Edit</h3>
              <button class="modal-close" @click="closeEditModeModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>

            <div class="modal-body modal-choice-body">
              <p class="choice-subtitle">Pilih tindakan untuk barang <b>{{ editModeModal.row?.nama }}</b></p>

              <div class="choice-grid">
                <button
                  type="button"
                  class="choice-card"
                  :class="{ 'choice-card--active': editModeModal.selected === 0 }"
                  @click="chooseEditMode('identity')"
                  @mouseenter="editModeModal.selected = 0"
                >
                  <span class="choice-icon"><i class="pi pi-file-edit"></i></span>
                  <span class="choice-title">Edit Data Barang</span>
                  <span class="choice-desc">Ubah kode, nama, deskripsi, dan foto barang.</span>
                </button>

                <button
                  type="button"
                  class="choice-card"
                  :class="{ 'choice-card--active': editModeModal.selected === 1 }"
                  @click="chooseEditMode('stock')"
                  @mouseenter="editModeModal.selected = 1"
                >
                  <span class="choice-icon"><i class="pi pi-warehouse"></i></span>
                  <span class="choice-title">Edit Stok & Harga</span>
                  <span class="choice-desc">Ubah stok dan harga per supplier dengan validasi perubahan.</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ---------------------------------------------------
         MODAL TAMBAH / EDIT BARANG
    ---------------------------------------------------- -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="modal.show && !isStockOnlyEdit" class="modal-overlay" @keydown="onModalKeydown" @click.self="closeModal">
          <div class="modal-box modal-box--edit" role="dialog" :aria-label="modal.title">
            <!-- Blue header -->
            <div class="modal-header modal-header--blue modal-header--center">
              <h3 class="modal-title">{{ modal.title }}</h3>
              <button class="modal-close" @click="closeModal" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>

            <form @submit.prevent="submitModal" class="modal-body modal-body--compact">

              <!-- Kode + Nama in one row -->
              <div class="mfield-row">
                <div class="mfield">
                  <label class="mfield-label">Kode Barang</label>
                  <input
                    v-model="form.kode"
                    ref="inputKode"
                    class="mfield-input"
                    placeholder="CDX-001"
                    :readonly="true"
                    :class="{ 'mfield-input--readonly': true }"
                    @keydown.enter.prevent="focusField('inputNama')"
                    required
                  />
                </div>
                <div class="mfield mfield--grow">
                  <label class="mfield-label">Nama Barang</label>
                  <input
                    v-model="form.nama"
                    ref="inputNama"
                    class="mfield-input"
                    placeholder="Nama barang"
                    :readonly="isStockOnlyEdit"
                    :class="{ 'mfield-input--readonly': isStockOnlyEdit }"
                    @keydown.enter.prevent="focusField('inputDeskripsi')"
                    required
                  />
                </div>
              </div>

              <!-- Deskripsi -->
              <div class="mfield">
                <label class="mfield-label">Deskripsi <span class="mfield-optional">(opsional)</span></label>
                <textarea
                  v-model="form.deskripsi"
                  ref="inputDeskripsi"
                  class="mfield-input mfield-textarea"
                  :class="{ 'mfield-input--readonly': isStockOnlyEdit }"
                  :readonly="isStockOnlyEdit"
                  rows="3"
                  placeholder="Deskripsi barang…"
                  @keydown.enter.exact.prevent="focusField('photoAreaRef')"
                ></textarea>
              </div>

              <!-- Foto Barang -->
              <div class="photo-section">
                <div class="photo-section-header">
                  <span class="photo-section-title"><i class="pi pi-images"></i> Foto Barang</span>
                  <span v-if="!isStockOnlyEdit" class="photo-limit">Maks 3 foto · <kbd>F1</kbd> tambah</span>
                </div>

                <div class="photo-area" ref="photoAreaRef" tabindex="0"
                  @keydown.enter.prevent="onPhotoAreaEnter"
                  @keydown.f1.prevent="triggerFileInput"
                  @keydown.backspace.prevent="removeLastFoto"
                  @keydown.tab.prevent="focusFirstSupplier"
                >
                  <!-- Previews -->
                  <div v-if="displayedFotos.length > 0" class="photo-preview-grid">
                    <div v-for="(photo, idx) in displayedFotos" :key="photo.key" class="photo-preview-item">
                      <img :src="photo.url" :alt="`Foto ${idx + 1}`" class="photo-preview-img" />
                      <button
                        v-if="!isStockOnlyEdit"
                        type="button"
                        class="photo-remove-btn"
                        @click="removeFoto(photo)"
                        title="Hapus foto"
                      >
                        <i class="pi pi-times"></i>
                      </button>
                    </div>
                  </div>

                  <!-- Upload trigger -->
                  <div
                    v-if="!isStockOnlyEdit && displayedFotos.length < 3"
                    class="photo-upload-area"
                  >
                    <input
                      ref="fileInput"
                      type="file"
                      accept="image/*"
                      multiple
                      class="photo-file-input"
                      @change="handleFileSelect"
                      :disabled="photoUpload.uploading"
                    />
                    <input
                      ref="fileInputCamera"
                      type="file"
                      accept="image/*"
                      capture="environment"
                      class="photo-file-input"
                      @change="handleFileSelect"
                      :disabled="photoUpload.uploading"
                    />
                    <div class="photo-upload-actions">
                      <button
                        type="button"
                        class="photo-action-btn photo-action-btn--camera"
                        @click="triggerCameraInput"
                        :disabled="photoUpload.uploading"
                      >
                        <i class="pi pi-camera"></i>
                        Ambil Foto
                      </button>
                      <button
                        type="button"
                        class="photo-action-btn"
                        @click="triggerFileInput"
                        :disabled="photoUpload.uploading"
                      >
                        <i class="pi pi-upload"></i>
                        Unggah Foto
                      </button>
                    </div>
                    <div class="photo-upload-label">
                      <i class="pi pi-cloud-upload"></i>
                      <span v-if="!photoUpload.uploading">Pilih Ambil Foto atau Unggah Foto · <kbd>F1</kbd> unggah cepat</span>
                      <span v-else class="uploading-text">
                        <i class="pi pi-spin pi-spinner"></i> Mengupload... {{ photoUpload.progress }}%
                      </span>
                    </div>
                  </div>
                  <div v-if="photoUpload.error" class="photo-upload-error">
                    <i class="pi pi-exclamation-circle"></i> {{ photoUpload.error }}
                  </div>
                </div>
              </div>

              <!-- Stok & Harga per Supplier -->
              <div class="price-section">
                <div class="price-section-header">
                  <span class="price-section-title"><i class="pi pi-truck"></i> Stok & Harga per Supplier</span>
                  <button
                    v-if="!isIdentityOnlyEdit"
                    type="button"
                    class="btn-add-supplier"
                    @click="addPriceRow"
                    tabindex="-1"
                  >
                    <i class="pi pi-plus"></i>
                    <span class="btn-label">Tambah</span>
                  </button>
                </div>

                <div
                  v-for="(pr, idx) in form.prices"
                  :key="idx"
                  class="price-row"
                  :class="{ 'price-row--active': modal.activePriceRow === idx }"
                >
                  <!-- Supplier search -->
                  <div class="supplier-search-wrap">
                    <input
                      :ref="el => { if (el) priceSupplierRefs[idx] = el }"
                      v-model="pr.supplierSearch"
                      class="price-supplier-input"
                      placeholder="Cari supplier..."
                      :readonly="isIdentityOnlyEdit"
                      :class="{ 'mfield-input--readonly': isIdentityOnlyEdit }"
                      autocomplete="off"
                      @focus="modal.activePriceRow = idx; openSupplierDropdown(idx)"
                      @input="filterSuppliers(idx)"
                      @keydown="onSupplierSearchKey($event, idx)"
                    />
                    <!-- Supplier dropdown (fixed position to escape modal overflow) -->
                    <Teleport to="body">
                      <div
                        v-if="pr.dropdownOpen && pr.filteredSuppliers?.length"
                        class="supplier-dropdown"
                        :style="{ top: dropdownPos.top + 'px', left: dropdownPos.left + 'px', width: dropdownPos.width + 'px' }"
                      >
                        <div
                          v-for="(s, si) in pr.filteredSuppliers"
                          :key="s.id"
                          class="supplier-dropdown-item"
                          :class="{ active: pr.dropdownIndex === si }"
                          @mousedown.prevent="selectSupplier(idx, s)"
                        >
                          {{ s.nama }}
                        </div>
                      </div>
                    </Teleport>
                  </div>

                  <!-- Stok -->
                  <div class="price-input-wrap price-input-wrap--stok">
                    <input
                      :ref="el => { if (el) priceStokRefs[idx] = el }"
                      v-model.number="pr.stok"
                      type="number"
                      class="price-input"
                      min="0"
                      :readonly="isIdentityOnlyEdit"
                      :class="{ 'mfield-input--readonly': isIdentityOnlyEdit }"
                      placeholder="0"
                      @keydown.enter.prevent="focusPriceHarga(idx)"
                    />
                  </div>

                  <!-- Harga -->
                  <div class="price-input-wrap">
                    <span class="price-prefix">Rp</span>
                    <input
                      :ref="el => { if (el) priceHargaRefs[idx] = el }"
                      :value="formatHargaInput(pr.harga_beli)"
                      type="text"
                      class="price-input"
                      inputmode="numeric"
                      :readonly="isIdentityOnlyEdit"
                      :class="{ 'mfield-input--readonly': isIdentityOnlyEdit }"
                      placeholder="0"
                      @input="onHargaInput(idx, $event)"
                      @keydown.enter.prevent="onHargaEnter(idx)"
                    />
                  </div>

                  <!-- Delete row -->
                  <button
                    v-if="!isIdentityOnlyEdit"
                    type="button"
                    class="btn-rm-supplier"
                    @click="removePriceRow(idx)"
                    :disabled="form.prices.length === 1"
                    tabindex="-1"
                  ><i class="pi pi-trash"></i></button>
                </div>
              </div>

              <div v-if="modal.error" class="modal-error">
                <i class="pi pi-exclamation-triangle"></i> {{ modal.error }}
              </div>

              <div class="modal-footer">
                <button type="button" class="btn-cancel" @click="closeModal({ backToChoice: true })">
                  <i class="pi pi-times"></i>
                  <span class="btn-label">{{ modal.mode === 'edit' ? 'Kembali' : 'Batal' }}</span>
                  <kbd>Esc</kbd>
                </button>
                <button type="submit" class="btn-save" :disabled="modal.saving" ref="btnSave">
                  <i v-if="modal.saving" class="pi pi-spin pi-spinner"></i>
                  <template v-else>
                    <i class="pi pi-check"></i>
                    <span class="btn-label">{{ modal.mode === 'add' ? 'Simpan' : 'Update' }}</span>
                    <kbd>Enter</kbd>
                  </template>
                </button>
              </div>
            </form>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ---------------------------------------------------
         MODAL KHUSUS EDIT STOK & HARGA
    ---------------------------------------------------- -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="modal.show && isStockOnlyEdit" class="modal-overlay" @keydown="onModalKeydown" @click.self="closeModal({ backToChoice: true })">
          <div class="modal-box modal-box--stock" role="dialog" aria-label="Edit stok dan harga">
            <div class="modal-header modal-header--blue modal-header--center">
              <h3 class="modal-title">Edit Stok & Harga</h3>
              <button class="modal-close" @click="closeModal({ backToChoice: true })" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>

            <form @submit.prevent="submitModal" class="modal-body modal-body--compact">
              <div class="mfield-row">
                <div class="mfield">
                  <label class="mfield-label">Kode Barang</label>
                  <input :value="form.kode" class="mfield-input mfield-input--readonly" readonly />
                </div>
                <div class="mfield mfield--grow">
                  <label class="mfield-label">Nama Barang</label>
                  <input :value="form.nama" class="mfield-input mfield-input--readonly" readonly />
                </div>
              </div>

              <div class="price-section">
                <div class="price-section-header">
                  <span class="price-section-title"><i class="pi pi-truck"></i> Stok & Harga per Supplier</span>
                  <button type="button" class="btn-add-supplier" @click="addPriceRow" tabindex="-1">
                    <i class="pi pi-plus"></i>
                    <span class="btn-label">Tambah</span>
                    <kbd class="kbd-f2">F2</kbd>
                  </button>
                </div>

                <div
                  v-for="(pr, idx) in form.prices"
                  :key="idx"
                  class="price-row"
                  :class="{ 'price-row--active': modal.activePriceRow === idx }"
                >
                  <div class="supplier-search-wrap">
                    <input
                      :ref="el => { if (el) priceSupplierRefs[idx] = el }"
                      v-model="pr.supplierSearch"
                      class="price-supplier-input"
                      placeholder="Cari nama supplier (F1)"
                      autocomplete="off"
                      @focus="modal.activePriceRow = idx; onStockSupplierFocus(idx)"
                      @input="onStockSupplierInput(idx)"
                      @keydown="onSupplierSearchKey($event, idx)"
                    />
                    <Teleport to="body">
                      <div
                        v-if="pr.dropdownOpen && pr.filteredSuppliers?.length"
                        class="supplier-dropdown"
                        :style="{ top: dropdownPos.top + 'px', left: dropdownPos.left + 'px', width: dropdownPos.width + 'px' }"
                      >
                        <div
                          v-for="(s, si) in pr.filteredSuppliers"
                          :key="s.id"
                          class="supplier-dropdown-item"
                          :class="{ active: pr.dropdownIndex === si }"
                          @mousedown.prevent="selectSupplier(idx, s)"
                        >
                          {{ s.nama }}
                        </div>
                      </div>
                    </Teleport>
                  </div>

                  <div class="price-input-wrap price-input-wrap--stok">
                    <input
                      :ref="el => { if (el) priceStokRefs[idx] = el }"
                      v-model.number="pr.stok"
                      type="number"
                      class="price-input"
                      min="0"
                      step="0.001"
                      placeholder="0"
                      @keydown.enter.prevent="focusPriceHarga(idx)"
                    />
                  </div>

                  <div class="price-input-wrap">
                    <span class="price-prefix">Rp</span>
                    <input
                      :ref="el => { if (el) priceHargaRefs[idx] = el }"
                      :value="formatHargaInput(pr.harga_beli)"
                      type="text"
                      class="price-input"
                      inputmode="numeric"
                      placeholder="0"
                      @input="onHargaInput(idx, $event)"
                      @keydown.enter.prevent="onHargaEnter(idx)"
                    />
                  </div>

                  <button
                    type="button"
                    class="btn-rm-supplier"
                    @click="removePriceRow(idx)"
                    :disabled="form.prices.length === 1"
                    tabindex="-1"
                  ><i class="pi pi-trash"></i></button>
                </div>
              </div>

              <div class="stock-validate-section">
                <div class="stock-validate-title"><i class="pi pi-verified"></i> Validasi Perubahan Stok</div>
                <div class="mfield-row">
                  <div class="mfield">
                    <label class="mfield-label">Tanggal Diubah</label>
                    <input
                      v-model="stockValidation.tanggal"
                      ref="stockTanggalRef"
                      type="date"
                      class="mfield-input"
                      @keydown.enter.prevent="stockPetugasRef?.focus()"
                      required
                    />
                  </div>
                  <div class="mfield mfield--grow">
                    <label class="mfield-label">Diubah Oleh</label>
                    <input
                      v-model="stockValidation.diubahOleh"
                      ref="stockPetugasRef"
                      class="mfield-input"
                      placeholder="Nama Staff"
                      maxlength="80"
                      @keydown.enter.prevent="stockAlasanRef?.focus()"
                      required
                    />
                  </div>
                </div>
                <div class="mfield stock-reason-field">
                  <label class="mfield-label">Alasan Diubah</label>
                  <textarea
                    v-model="stockValidation.alasan"
                    ref="stockAlasanRef"
                    class="mfield-input mfield-textarea stock-reason-input"
                    rows="2"
                    placeholder="Contoh: koreksi stok fisik setelah stock opname"
                    @keydown.enter.exact.prevent="onStockReasonEnter"
                    required
                  ></textarea>
                </div>
              </div>

              <div v-if="modal.error" class="modal-error">
                <i class="pi pi-exclamation-triangle"></i> {{ modal.error }}
              </div>

              <div class="modal-footer">
                <button type="button" class="btn-cancel" @click="closeModal({ backToChoice: true })">
                  <i class="pi pi-arrow-left"></i>
                  <span class="btn-label">Kembali</span>
                  <kbd>Esc</kbd>
                </button>
                <button type="submit" class="btn-save" :disabled="modal.saving" ref="btnSave">
                  <i v-if="modal.saving" class="pi pi-spin pi-spinner"></i>
                  <template v-else>
                    <i class="pi pi-check"></i>
                    <span class="btn-label">Update</span>
                    <kbd>Enter</kbd>
                  </template>
                </button>
              </div>
            </form>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ---------------------------------------------------
         MODAL KONFIRMASI ARCHIVE
    ---------------------------------------------------- -->
    <Teleport to="body">
      <Transition name="modal">
        <div v-if="archiveModal.show" class="modal-overlay" @click.self="archiveModal.show = false">
          <div class="modal-box modal-box--sm" role="dialog">
            <div class="modal-header modal-header--archive modal-header--center">
              <h3 class="modal-title"><i class="pi pi-inbox"></i> Archive Barang</h3>
              <button class="modal-close" @click="archiveModal.show = false" tabindex="-1">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body delete-body">
              <i class="pi pi-inbox del-icon" style="color:#f59e0b"></i>
              <p>Archive barang <b>{{ archiveModal.row?.nama }}</b>?</p>
              <p class="del-warn">Barang akan dipindahkan ke menu Archive dan bisa dibuka kembali kapan saja.</p>
            </div>
            <div class="modal-footer">
              <button class="btn-cancel" @click="archiveModal.show = false">
                <i class="pi pi-times"></i>
                <span class="btn-label">Batal</span>
                <kbd>Esc</kbd>
              </button>
              <button class="btn-archive" @click="doArchive" :disabled="archiveModal.saving">
                <i v-if="archiveModal.saving" class="pi pi-spin pi-spinner"></i>
                <template v-else>
                  <i class="pi pi-inbox"></i>
                  <span class="btn-label">Archive</span>
                </template>
              </button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- -- MODAL: PILIH BARANG ------------------------------ -->
    <Teleport to="body">
      <Transition name="modal-fade">
        <div v-if="barangModal.show" class="modal-backdrop" @click="barangModal.show = false">
          <div class="modal-box modal-lg" @click.stop>
            <div class="modal-header modal-header--center">
              <h3 class="modal-title">Pilih Barang</h3>
              <button class="modal-close" @click="barangModal.show = false">
                <i class="pi pi-times"></i>
              </button>
            </div>
            <div class="modal-body">
              <div class="search-input-wrap" style="margin-bottom: 1rem;">
                <i class="pi pi-search si-icon"></i>
                <input
                  ref="barangModalInput"
                  v-model="barangModal.query"
                  type="text"
                  class="search-input"
                  placeholder="Ketik untuk filter…"
                  @input="filterBarangModal"
                  @keydown="onBarangModalKey"
                />
              </div>
              <div class="modal-list" ref="barangModalListRef">
                <div
                  v-for="(p, i) in barangModal.filtered"
                  :key="p.id"
                  class="modal-item"
                  :class="{ 'modal-item--active': barangModal.selectedIndex === i }"
                  @click="selectBarangFromModal(p)"
                  @mouseenter="barangModal.selectedIndex = i"
                >
                  <i class="pi pi-box"></i>
                  <div class="modal-item-detail">
                    <span class="modal-item-nama">{{ p.nama }}</span>
                    <span class="modal-item-meta">{{ p.kode }} · Stok: <b>{{ p.stok }}</b> {{ p.satuan }}</span>
                  </div>
                </div>
                <div v-if="!barangModal.filtered.length" class="empty-state">
                  <i class="pi pi-inbox"></i>
                  <p>Tidak ada barang yang cocok</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <!-- ---------------------------------------------------
         LIGHTBOX FOTO
    ---------------------------------------------------- -->
    <Teleport to="body">
      <Transition name="modal-fade">
        <div v-if="lightbox.show" class="lightbox-overlay" @click="closeLightbox">
          <div class="lightbox-content" @click.stop>
            <button class="lightbox-close" @click="closeLightbox">
              <i class="pi pi-times"></i>
            </button>
            <button
              v-if="lightbox.currentIndex > 0"
              class="lightbox-prev"
              @click="prevPhoto"
            >
              <i class="pi pi-chevron-left"></i>
            </button>
            <div class="lightbox-image-wrap">
              <img
                :src="lightbox.photos[lightbox.currentIndex]"
                :alt="`Foto ${lightbox.currentIndex + 1}`"
                class="lightbox-image"
              />
            </div>
            <button
              v-if="lightbox.currentIndex < lightbox.photos.length - 1"
              class="lightbox-next"
              @click="nextPhoto"
            >
              <i class="pi pi-chevron-right"></i>
            </button>
            <div class="lightbox-counter">
              {{ lightbox.currentIndex + 1 }} / {{ lightbox.photos.length }}
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>

    <Toast position="top-right" />
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'
import { supabase } from '@/lib/supabase'
import { useToast } from 'primevue/usetoast'
import Toast from 'primevue/toast'
import { useRouter } from 'vue-router'

const router = useRouter()
const toast = useToast()
const PAGE_SIZE = 15
const GUDANG_KATALOG_STATE_KEY = 'gudang-katalog-state-v1'

// -- DOM Refs -----------------------------------------------
const pageEl        = ref(null)
const inputBarang   = ref(null)
const photoViewRef  = ref(null)
const rowRefs       = new Map()
const inputKode     = ref(null)
const inputNama     = ref(null)
const inputDeskripsi = ref(null)
const photoAreaRef  = ref(null)
const btnSave       = ref(null)
const fileInput     = ref(null)
const fileInputCamera = ref(null)
const editModeModalRef = ref(null)
const stockTanggalRef = ref(null)
const stockPetugasRef = ref(null)
const stockAlasanRef = ref(null)
const priceSupplierRefs = ref({})
const priceStokRefs     = ref({})
const priceHargaRefs    = ref({})

function setRowRef(el, i) {
  if (el) rowRefs.set(i, el)
  else    rowRefs.delete(i)
}

// -- State --------------------------------------------------
const searchBarang     = ref('')
const isFocused        = ref(false)
const lastSearch       = ref('')
const hasSearched      = ref(false)
const loading          = ref(false)
const allRows          = ref([])
const selectedRowIndex = ref(-1)
const currentPage      = ref(1)
const suppliers        = ref([])

const barangModal = reactive({
  show: false, query: '', results: [], filtered: [], selectedIndex: 0,
})
const barangModalInput = ref(null)
const barangModalListRef = ref(null)

const editModeModal = reactive({
  show: false,
  selected: 0,
  row: null,
})

const modal = reactive({
  show: false, mode: 'add', title: '', saving: false, error: '',
  variant: 'full',
  activePriceRow: 0,
})
const dropdownPos = reactive({ top: 0, left: 0, width: 0 })
const form = reactive({
  id: null, kode: '', nama: '', deskripsi: '', stok: 0, satuan: 'pcs',
  prices: [makePriceRowDefault()],
  foto_urls: [],
})
const photoUpload = reactive({ uploading: false, progress: 0, error: '' })
const lightbox    = reactive({ show: false, photos: [], currentIndex: 0 })
const archiveModal  = reactive({ show: false, row: null, saving: false })
const stockValidation = reactive({ tanggal: '', diubahOleh: '', alasan: '' })
const pendingFotoFiles = ref([])
const autoKodeSuffix = ref(generateRandomKodeSuffix())


// -- Computed -----------------------------------------------
const totalRows  = computed(() => allRows.value.length)
const totalPages = computed(() => Math.max(1, Math.ceil(totalRows.value / PAGE_SIZE)))
const pagedRows  = computed(() => {
  const start = (currentPage.value - 1) * PAGE_SIZE
  return allRows.value.slice(start, start + PAGE_SIZE)
})
const selectedRowData = computed(() => {
  if (selectedRowIndex.value >= 0 && pagedRows.value[selectedRowIndex.value]) {
    return pagedRows.value[selectedRowIndex.value]
  }
  return null
})
const displayedFotos = computed(() => {
  const existing = (form.foto_urls ?? []).map((url, idx) => ({
    key: `remote-${idx}-${url}`,
    url,
    origin: 'remote',
    index: idx,
  }))
  const pending = pendingFotoFiles.value.map((item, idx) => ({
    key: `pending-${idx}-${item.previewUrl}`,
    url: item.previewUrl,
    origin: 'pending',
    index: idx,
  }))
  return [...existing, ...pending]
})
const isIdentityOnlyEdit = computed(() => modal.mode === 'edit' && modal.variant === 'identity')
const isStockOnlyEdit = computed(() => modal.mode === 'edit' && modal.variant === 'stock')

// -- Utilities ----------------------------------------------
function formatRp(val) {
  return 'Rp ' + Number(val).toLocaleString('id-ID')
}

function formatHargaInput(val) {
  const num = Number(val)
  if (!Number.isFinite(num) || num <= 0) return ''
  return num.toLocaleString('id-ID')
}

function parseHargaInput(raw) {
  const digits = String(raw ?? '').replace(/\D/g, '')
  if (!digits) return 0
  return Number(digits)
}

function isMissingSupabaseTableError(err) {
  const code = String(err?.code || '')
  if (code === 'PGRST205' || code === '42P01') return true
  const message = String(err?.message || '').toLowerCase()
  return message.includes('could not find the table') || (message.includes('relation') && message.includes('does not exist'))
}

function isMissingSupabaseColumnError(err) {
  const code = String(err?.code || '')
  if (code === '42703') return true
  const message = String(err?.message || '').toLowerCase()
  return message.includes('column') && message.includes('does not exist')
}

async function ensureStockAdjustmentHistoryTable() {
  const { error } = await supabase
    .from('stock_adjustments')
    .select('id, product_kode, product_nama, adjustment_date, stock_before, stock_after, qty_delta, staff_nama, alasan')
    .limit(1)

  if (!error) return

  if (isMissingSupabaseTableError(error) || isMissingSupabaseColumnError(error)) {
    throw new Error('Tabel histori penyesuaian stok belum tersedia di database. Jalankan migrasi server/schema/21_add_stock_adjustments_history.sql terlebih dahulu.')
  }

  throw error
}

function generateRandomKodeSuffix() {
  return String(Math.floor(Math.random() * 10000)).padStart(4, '0')
}

function toSafeNumber(value, fallback = 0) {
  const num = Number(value)
  return Number.isFinite(num) ? num : fallback
}

function extractKodeSuffix(kode) {
  const match = String(kode || '').trim().match(/(\d{4})$/)
  return match?.[1] || ''
}

function normalizeKodeValue(kode) {
  return String(kode || '')
    .toUpperCase()
    .replace(/\s+/g, ' ')
    .trim()
}

function normalizeNameValue(value) {
  return String(value || '')
    .toLowerCase()
    .normalize('NFKC')
    .replace(/\s+/g, ' ')
    .trim()
}

function resolveSupplierIdFromInput(rawName) {
  const query = normalizeNameValue(rawName)
  if (!query) return ''

  const exact = suppliers.value.find(s => normalizeNameValue(s.nama) === query)
  if (exact?.id) return exact.id

  const fuzzy = suppliers.value.filter(s => normalizeNameValue(s.nama).includes(query))
  if (fuzzy.length === 1) return fuzzy[0].id

  if (fuzzy.length > 1) {
    throw new Error(`Nama supplier "${rawName}" ambigu. Ketik lebih lengkap.`)
  }

  throw new Error(`Supplier "${rawName}" tidak ditemukan.`)
}

function buildNormalizedPriceRowsForSubmit() {
  return form.prices
    .map(pr => {
      const supplierSearch = String(pr.supplierSearch || '').trim()
      const supplierIdFromName = supplierSearch ? resolveSupplierIdFromInput(supplierSearch) : ''
      const supplierId = supplierIdFromName || pr.supplier_id || ''
      return {
        price_id: pr.price_id || null,
        supplier_id: supplierId,
        supplierSearch,
        stok: Math.max(0, toSafeNumber(pr.stok, 0)),
        harga_beli: Math.max(0, toSafeNumber(pr.harga_beli, 0)),
      }
    })
    .filter(pr => Boolean(pr.supplier_id))
}

function consolidatePriceRowsForSubmit(priceRows) {
  const bySupplier = new Map()

  for (const row of priceRows) {
    if (!row?.supplier_id) continue
    const supplierId = String(row.supplier_id)
    const stok = Math.max(0, toSafeNumber(row.stok, 0))
    const harga = Math.max(0, toSafeNumber(row.harga_beli, 0))

    if (!bySupplier.has(supplierId)) {
      bySupplier.set(supplierId, {
        supplier_id: row.supplier_id,
        stok: Number(stok.toFixed(3)),
        harga_beli: harga,
      })
      continue
    }

    const current = bySupplier.get(supplierId)
    current.stok = Number((current.stok + stok).toFixed(3))
    current.harga_beli = harga > 0 ? harga : current.harga_beli
    bySupplier.set(supplierId, current)
  }

  return Array.from(bySupplier.values())
}

function getSupplierNamaById(supplierId) {
  if (!supplierId) return 'Supplier tidak dikenal'
  const found = suppliers.value.find(item => String(item.id) === String(supplierId))
  return found?.nama || 'Supplier tidak dikenal'
}

function buildSupplierStockMap(rows = []) {
  const map = new Map()

  for (const row of rows) {
    const supplierId = row?.supplier_id
    if (!supplierId) continue
    map.set(String(supplierId), Math.max(0, toSafeNumber(row?.stok, 0)))
  }

  return map
}

function buildSupplierAdjustmentEntries({
  productId,
  productKode,
  productNama,
  validationTanggal,
  validationStaff,
  validationAlasan,
  previousRows,
  nextRows,
}) {
  const previousMap = buildSupplierStockMap(previousRows)
  const nextMap = buildSupplierStockMap(nextRows)
  const allSupplierIds = new Set([...previousMap.keys(), ...nextMap.keys()])

  const entries = []
  for (const supplierId of allSupplierIds) {
    const stockBefore = Number((previousMap.get(supplierId) || 0).toFixed(3))
    const stockAfter = Number((nextMap.get(supplierId) || 0).toFixed(3))
    const qtyDelta = Number((stockAfter - stockBefore).toFixed(3))

    if (Math.abs(qtyDelta) < 0.0005) continue

    const supplierNama = getSupplierNamaById(supplierId)
    entries.push({
      productId,
      productKode,
      productNama,
      previousStok: stockBefore,
      nextStok: stockAfter,
      validationTanggal,
      validationStaff,
      validationAlasan: `${String(validationAlasan || '').trim()} | Supplier ${supplierNama}: ${stockBefore} -> ${stockAfter}`,
    })
  }

  return entries
}

async function syncProductPrices(productId, priceRows) {
  const finalRows = consolidatePriceRowsForSubmit(priceRows)
  if (!finalRows.length) {
    throw new Error('Minimal ada 1 supplier yang valid.')
  }

  const { data: existingRows, error: existingError } = await supabase
    .from('product_prices')
    .select('id, supplier_id')
    .eq('product_id', productId)

  if (existingError) throw existingError

  for (const row of finalRows) {
    const { error: upsertError } = await supabase
      .from('product_prices')
      .upsert({
        product_id: productId,
        supplier_id: row.supplier_id,
        stok: row.stok,
        harga_beli: row.harga_beli,
        aktif: true,
      }, { onConflict: 'product_id,supplier_id' })

    if (upsertError) throw upsertError
  }

  const finalSupplierIds = new Set(finalRows.map(row => String(row.supplier_id)))
  const inactiveIds = (existingRows || [])
    .filter(row => row?.id && !finalSupplierIds.has(String(row.supplier_id)))
    .map(row => row.id)

  if (inactiveIds.length) {
    const { error: deactivateError } = await supabase
      .from('product_prices')
      .update({ stok: 0, aktif: false })
      .in('id', inactiveIds)

    if (deactivateError) throw deactivateError
  }

  return finalRows
}

function buildKodePrefixFromNama(nama) {
  const words = String(nama || '')
    .trim()
    .split(/\s+/)
    .map(part => part.replace(/[^A-Za-z]/g, '').toUpperCase())
    .filter(Boolean)

  const firstWord = words[0] || ''
  const len = firstWord.length
  if (!len) return ''

  if (len === 2) return firstWord.slice(0, 2)
  if (len === 4) return firstWord.slice(0, 4)
  if (len > 4) {
    const middleIndex = Math.floor((len - 1) / 2)
    return `${firstWord[0]}${firstWord[middleIndex]}${firstWord[len - 1]}`
  }

  return firstWord.slice(0, Math.min(3, len))
}

function syncAutoGeneratedKodePreview() {
  if (isStockOnlyEdit.value) return
  const prefix = buildKodePrefixFromNama(form.nama)
  form.kode = prefix ? `${prefix} ${autoKodeSuffix.value}` : ''
}

function isKodeFollowingLatestRule(kode, nama) {
  const prefix = buildKodePrefixFromNama(nama)
  if (!prefix) return true

  const normalizedKode = normalizeKodeValue(kode)
  const match = normalizedKode.match(/^([A-Z]{2,4})\s(\d{4})$/)
  if (!match) return false
  return match[1] === prefix
}

function createUniqueKodeForPrefix(prefix, usedKodeSet) {
  for (let attempt = 0; attempt < 10000; attempt += 1) {
    const candidate = `${prefix} ${generateRandomKodeSuffix()}`
    if (usedKodeSet.has(candidate)) continue
    usedKodeSet.add(candidate)
    return candidate
  }

  throw new Error(`Gagal membuat kode unik untuk prefix ${prefix}.`)
}

async function autoNormalizeLegacyProductCodes() {
  const FETCH_SIZE = 1000
  const rows = []
  let from = 0

  while (true) {
    const to = from + FETCH_SIZE - 1
    const { data, error } = await supabase
      .from('products')
      .select('id, nama, kode')
      .order('id', { ascending: true })
      .range(from, to)

    if (error) throw error

    const chunk = Array.isArray(data) ? data : []
    if (!chunk.length) break

    rows.push(...chunk)

    if (chunk.length < FETCH_SIZE) break
    from += FETCH_SIZE
  }

  if (!rows.length) return

  const usedKodeSet = new Set(
    rows
      .map(row => normalizeKodeValue(row.kode))
      .filter(Boolean)
  )

  const updates = []

  for (const row of rows) {
    const prefix = buildKodePrefixFromNama(row.nama)
    if (!prefix) continue
    if (isKodeFollowingLatestRule(row.kode, row.nama)) continue

    const currentKode = normalizeKodeValue(row.kode)
    if (currentKode) {
      usedKodeSet.delete(currentKode)
    }

    const existingSuffix = extractKodeSuffix(row.kode)
    const preferredKode = /^\d{4}$/.test(existingSuffix) ? `${prefix} ${existingSuffix}` : ''

    let nextKode = ''
    if (preferredKode && !usedKodeSet.has(preferredKode)) {
      nextKode = preferredKode
      usedKodeSet.add(nextKode)
    } else {
      nextKode = createUniqueKodeForPrefix(prefix, usedKodeSet)
    }

    updates.push({ id: row.id, kode: nextKode })
  }

  if (!updates.length) return

  const CHUNK_SIZE = 30
  for (let i = 0; i < updates.length; i += CHUNK_SIZE) {
    const chunk = updates.slice(i, i + CHUNK_SIZE)
    const results = await Promise.all(
      chunk.map(item =>
        supabase
          .from('products')
          .update({ kode: item.kode })
          .eq('id', item.id)
      )
    )

    const failed = results.find(result => result.error)
    if (failed?.error) {
      throw failed.error
    }
  }

}

async function generateUniqueAutoKode(nama, excludeProductId = null, preferredSuffix = '') {
  const prefix = buildKodePrefixFromNama(nama)
  if (!prefix) {
    throw new Error('Nama barang harus berisi huruf agar kode dapat digenerate otomatis.')
  }

  const usedSuffixes = new Set()
  const initialSuffix = String(preferredSuffix || '').trim()

  for (let attempt = 0; attempt < 40; attempt += 1) {
    let suffix = attempt === 0 && /^\d{4}$/.test(initialSuffix)
      ? initialSuffix
      : generateRandomKodeSuffix()

    while (usedSuffixes.has(suffix)) {
      suffix = generateRandomKodeSuffix()
    }
    usedSuffixes.add(suffix)

    const kodeCandidate = `${prefix} ${suffix}`
    const { data, error } = await supabase
      .from('products')
      .select('id')
      .eq('kode', kodeCandidate)
      .limit(1)
      .maybeSingle()

    if (error) throw error

    if (!data || String(data.id) === String(excludeProductId || '')) {
      return kodeCandidate
    }
  }

  throw new Error('Gagal membuat kode barang unik. Silakan coba simpan lagi.')
}

function onHargaInput(idx, event) {
  const pr = form.prices[idx]
  if (!pr) return
  const nextValue = parseHargaInput(event?.target?.value)
  pr.harga_beli = nextValue
  if (event?.target) {
    event.target.value = formatHargaInput(nextValue)
  }
}

function makePriceRowDefault(overrides = {}) {
  return {
    price_id: null, supplier_id: '', supplierSearch: '',
    filteredSuppliers: [], dropdownOpen: false, dropdownIndex: 0,
    stok: 0, harga_beli: 0, ...overrides,
  }
}

function clearPendingFotoFiles() {
  for (const item of pendingFotoFiles.value) {
    if (item?.previewUrl) URL.revokeObjectURL(item.previewUrl)
  }
  pendingFotoFiles.value = []
}

// -- Search / Table -----------------------------------------
async function openBarangModal() {
  const q = searchBarang.value.trim()
  if (!q) return

  const { data, error } = await supabase
    .from('products')
    .select('*')
    .or(`nama.ilike.%${q}%,kode.ilike.%${q}%`)
    .eq('aktif', true)
    .eq('is_archived', false)
    .order('nama')

  if (error) { console.error('[openBarangModal]', error); return }

  barangModal.results  = data || []
  barangModal.filtered = data || []
  barangModal.query    = ''
  barangModal.selectedIndex = 0
  barangModal.show     = true
  await nextTick()
  barangModalInput.value?.focus()
}

function filterBarangModal() {
  const q = barangModal.query.toLowerCase()
  barangModal.filtered = q
    ? barangModal.results.filter(p =>
        p.nama.toLowerCase().includes(q) || p.kode.toLowerCase().includes(q))
    : barangModal.results
  barangModal.selectedIndex = 0
  nextTick(() => scrollBarangModalActiveIntoView())
}

function selectBarangFromModal(product) {
  barangModal.show  = false
  searchBarang.value = product.nama
  doSearch(product.id)
}

function onBarangModalKey(e) {
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    barangModal.selectedIndex = Math.min(barangModal.selectedIndex + 1, barangModal.filtered.length - 1)
    nextTick(() => scrollBarangModalActiveIntoView())
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    barangModal.selectedIndex = Math.max(barangModal.selectedIndex - 1, 0)
    nextTick(() => scrollBarangModalActiveIntoView())
  } else if (e.key === 'Enter') {
    e.preventDefault()
    if (barangModal.filtered[barangModal.selectedIndex]) {
      selectBarangFromModal(barangModal.filtered[barangModal.selectedIndex])
    }
  } else if (e.key === 'Escape') {
    barangModal.show = false
  }
}

function scrollBarangModalActiveIntoView() {
  const listEl = barangModalListRef.value
  if (!listEl) return
  const activeEl = listEl.querySelector('.modal-item--active')
  activeEl?.scrollIntoView({ block: 'nearest' })
}

async function doSearch(productId = null) {
  const q = searchBarang.value.trim()
  if (!productId && !q) return

  loading.value          = true
  hasSearched.value      = true
  lastSearch.value       = q
  currentPage.value      = 1
  selectedRowIndex.value = -1
  allRows.value          = []

  try {
    let query = supabase
      .from('products')
      .select(`
        id, kode, nama, deskripsi, stok, satuan, foto_urls,
        product_prices (
          id, harga_beli, aktif, stok,
          suppliers ( id, nama )
        )
      `)
      .eq('aktif', true)
      .eq('is_archived', false)
      .order('kode')

    if (productId) {
      query = query.eq('id', productId)
    } else {
      query = query.or(`nama.ilike.%${q}%,kode.ilike.%${q}%`)
    }

    const { data, error } = await query
    if (error) throw error

    const grouped = []
    for (const p of data ?? []) {
      const activePrices = p.product_prices?.filter(pp => pp.aktif && Number(pp.stok || 0) > 0) ?? []
      const prices = activePrices.map(pp => ({
        id: pp.id,
        supplier_id: pp.suppliers?.id ?? null,
        supplier_nama: pp.suppliers?.nama ?? null,
        harga_beli: pp.harga_beli,
        stok: pp.stok ?? 0,
      }))
      grouped.push({
        product_id: p.id, kode: p.kode, nama: p.nama, deskripsi: p.deskripsi,
        stok: p.stok, satuan: p.satuan, foto_urls: p.foto_urls ?? [], prices,
      })
    }
    allRows.value = grouped

    if (grouped.length > 0) {
      selectedRowIndex.value = 0
      nextTick(() => {
        rowRefs.get(0)?.focus?.() || rowRefs.get(0)?.scrollIntoView({ block: 'nearest' })
      })
    }
  } catch (err) {
    console.error('[Katalog] search:', err.message)
  } finally {
    loading.value = false
  }
}

function clearBarang() {
  searchBarang.value     = ''
  hasSearched.value      = false
  allRows.value          = []
  selectedRowIndex.value = -1
  lastSearch.value       = ''
}

function moveRow(delta) {
  const max = pagedRows.value.length - 1
  if (max < 0) return
  if (delta === 0) { selectedRowIndex.value = 0 }
  else { selectedRowIndex.value = Math.max(0, Math.min(max, selectedRowIndex.value + delta)) }
  nextTick(() => rowRefs.get(selectedRowIndex.value)?.scrollIntoView({ block: 'nearest' }))
}

function isMobileViewport() {
  return typeof window !== 'undefined' && window.matchMedia('(max-width: 768px)').matches
}

function onRowClick(row, index) {
  selectedRowIndex.value = index
  if (!isMobileViewport()) return
  openEditModeModal(row)
}

function prevPage() {
  if (currentPage.value > 1) { currentPage.value--; selectedRowIndex.value = 0 }
}
function nextPage() {
  if (currentPage.value < totalPages.value) { currentPage.value++; selectedRowIndex.value = 0 }
}

// -- Suppliers ----------------------------------------------
async function loadSuppliers() {
  const { data } = await supabase
    .from('suppliers').select('id, kode, nama').eq('aktif', true).order('nama')
  suppliers.value = data ?? []
}

// -- Modal Add / Edit ---------------------------------------
function resetForm() {
  form.id = null; form.kode = ''; form.nama = ''; form.deskripsi = ''
  form.stok = 0; form.satuan = 'pcs'
  form.prices = [makePriceRowDefault()]
  form.foto_urls = []
  clearPendingFotoFiles()
  stockValidation.tanggal = ''
  stockValidation.diubahOleh = ''
  stockValidation.alasan = ''
  photoUpload.uploading = false; photoUpload.progress = 0; photoUpload.error = ''
  priceSupplierRefs.value = {}
  priceStokRefs.value = {}
  priceHargaRefs.value = {}
}

function openAdd() {
  resetForm()
  autoKodeSuffix.value = generateRandomKodeSuffix()
  syncAutoGeneratedKodePreview()
  modal.mode = 'add'; modal.variant = 'full'; modal.title = 'Tambah Barang Baru'
  modal.error = ''; modal.activePriceRow = 0; modal.show = true
  nextTick(() => inputNama.value?.focus())
}

function openEdit(row, variant = 'full') {
  if (!row) return
  resetForm()
  form.id        = row.product_id
  form.kode      = row.kode
  form.nama      = row.nama
  form.deskripsi = row.deskripsi ?? ''
  form.stok      = row.stok
  form.satuan    = row.satuan
  form.foto_urls = row.foto_urls ?? []
  form.prices = row.prices?.length
    ? row.prices.map(p => makePriceRowDefault({
        price_id: p.id, supplier_id: p.supplier_id ?? '',
        supplierSearch: p.supplier_nama ?? '', stok: p.stok ?? 0, harga_beli: p.harga_beli ?? 0,
      }))
    : [makePriceRowDefault()]

  if (variant !== 'stock') {
    autoKodeSuffix.value = extractKodeSuffix(row.kode) || generateRandomKodeSuffix()
    syncAutoGeneratedKodePreview()
  }

  if (variant === 'stock') {
    stockValidation.tanggal = new Date().toISOString().slice(0, 10)
  }

  modal.mode = 'edit'
  modal.variant = variant
  modal.title = variant === 'identity' ? 'Edit Data Barang' : variant === 'stock' ? 'Edit Stok & Harga' : 'Edit Barang'
  modal.error = ''; modal.activePriceRow = 0; modal.show = true
  nextTick(() => {
    if (isStockOnlyEdit.value) priceSupplierRefs.value[0]?.focus()
    else inputNama.value?.focus()
  })
}

function openEditModeModal(row) {
  if (!row) return
  editModeModal.row = row
  editModeModal.selected = 0
  editModeModal.show = true
  nextTick(() => editModeModalRef.value?.focus())
}

function closeEditModeModal() {
  editModeModal.show = false
  editModeModal.row = null
}

function chooseEditMode(mode) {
  const row = editModeModal.row
  closeEditModeModal()
  if (!row) return
  if (mode === 'stock') openEdit(row, 'stock')
  else openEdit(row, 'identity')
}

function onEditModeModalKeydown(e) {
  if (!editModeModal.show) return
  if (e.key === 'ArrowRight') {
    e.preventDefault()
    editModeModal.selected = 1
  } else if (e.key === 'ArrowLeft') {
    e.preventDefault()
    editModeModal.selected = 0
  } else if (e.key === 'F1') {
    e.preventDefault()
    chooseEditMode('identity')
  } else if (e.key === 'F2') {
    e.preventDefault()
    chooseEditMode('stock')
  } else if (e.key === 'Enter') {
    e.preventDefault()
    chooseEditMode(editModeModal.selected === 0 ? 'identity' : 'stock')
  } else if (e.key === 'Escape') {
    e.preventDefault()
    closeEditModeModal()
  }
}

function closeModal({ backToChoice = false } = {}) {
  const reopenChoice = backToChoice && modal.mode === 'edit' && selectedRowData.value
  modal.show = false
  clearPendingFotoFiles()
  if (fileInput.value) fileInput.value.value = ''
  if (fileInputCamera.value) fileInputCamera.value.value = ''
  if (reopenChoice) {
    nextTick(() => openEditModeModal(selectedRowData.value))
  }
}

function addPriceRow() {
  if (isIdentityOnlyEdit.value) return
  form.prices.push(makePriceRowDefault())
  const newIdx = form.prices.length - 1
  modal.activePriceRow = newIdx
  nextTick(() => priceSupplierRefs.value[newIdx]?.focus())
}

function removePriceRow(i) {
  if (isIdentityOnlyEdit.value) return
  if (form.prices.length > 1) form.prices.splice(i, 1)
}

function focusField(refName) {
  const refMap = { inputKode, inputNama, inputDeskripsi, photoAreaRef, btnSave }
  nextTick(() => refMap[refName]?.value?.focus())
}

function triggerFileInput() { fileInput.value?.click() }

function triggerCameraInput() { fileInputCamera.value?.click() }

function focusFirstSupplier() {
  if (isIdentityOnlyEdit.value) {
    nextTick(() => btnSave.value?.focus())
    return
  }
  nextTick(() => priceSupplierRefs.value[0]?.focus())
}

function isUpdateFormReady() {
  if (!form.kode.trim() || !form.nama.trim()) return false
  if (isStockOnlyEdit.value) {
    if (!stockValidation.tanggal) return false
    if (!stockValidation.diubahOleh.trim()) return false
    if (!stockValidation.alasan.trim()) return false
  }
  return true
}

function shouldSubmitByEnter(target) {
  if (modal.mode !== 'edit' || !isUpdateFormReady()) return false
  if (isStockOnlyEdit.value) return target === stockAlasanRef.value || target === btnSave.value
  if (isIdentityOnlyEdit.value) return target === photoAreaRef.value || target === btnSave.value
  return target === btnSave.value
}

function onPhotoAreaEnter(e) {
  e?.stopPropagation?.()
  if (shouldSubmitByEnter(photoAreaRef.value)) {
    submitModal()
    return
  }
  focusFirstSupplier()
}

function onStockReasonEnter(e) {
  e?.stopPropagation?.()
  if (shouldSubmitByEnter(stockAlasanRef.value)) {
    submitModal()
  }
}

function onModalKeydown(e) {
  if (e.key === 'Escape') {
    e.preventDefault(); closeModal({ backToChoice: true })
  } else if (e.key === 'F1' && isStockOnlyEdit.value) {
    e.preventDefault()
    modal.activePriceRow = 0
    nextTick(() => {
      const firstSupplierInput = priceSupplierRefs.value[0]
      firstSupplierInput?.focus()
      firstSupplierInput?.select?.()
    })
  } else if (e.key === 'F2' && isStockOnlyEdit.value) {
    e.preventDefault()
    addPriceRow()
  } else if (e.key === 'Enter' && !e.shiftKey && shouldSubmitByEnter(e.target)) {
    e.preventDefault(); submitModal()
  } else if (e.key === 'Delete') {
    if (!e.target.matches('input,textarea,select') && !isIdentityOnlyEdit.value) {
      e.preventDefault(); removePriceRow(modal.activePriceRow)
    }
  }
}

// -- Supplier dropdown --------------------------------------
function calcDropdownPos(idx) {
  const el = priceSupplierRefs.value[idx]
  if (!el) return
  const rect = el.getBoundingClientRect()
  dropdownPos.top = rect.bottom + 4
  dropdownPos.left = rect.left
  dropdownPos.width = rect.width
}

function openSupplierDropdown(idx) {
  if (isIdentityOnlyEdit.value) return
  if (!form.prices[idx]) return
  form.prices.forEach((p, i) => { if (i !== idx) p.dropdownOpen = false })
  form.prices[idx].filteredSuppliers = suppliers.value.slice(0, 10)
  form.prices[idx].dropdownOpen = true
  form.prices[idx].dropdownIndex = 0
  nextTick(() => calcDropdownPos(idx))
}

function filterSuppliers(idx) {
  if (isIdentityOnlyEdit.value) return
  const pr = form.prices[idx]
  if (!pr) return
  pr.supplier_id = ''
  const q = pr.supplierSearch.toLowerCase()
  pr.filteredSuppliers = suppliers.value.filter(s => s.nama.toLowerCase().includes(q)).slice(0, 8)
  pr.dropdownOpen = pr.filteredSuppliers.length > 0
  pr.dropdownIndex = 0
  if (pr.dropdownOpen) nextTick(() => calcDropdownPos(idx))
}

function selectSupplier(idx, supplier) {
  if (isIdentityOnlyEdit.value) return
  const pr = form.prices[idx]
  if (!pr) return
  pr.supplier_id = supplier.id
  pr.supplierSearch = supplier.nama
  pr.dropdownOpen = false
  nextTick(() => priceStokRefs.value[idx]?.focus())
}

function onStockSupplierInput(idx) {
  if (!isStockOnlyEdit.value) {
    filterSuppliers(idx)
    return
  }

  const pr = form.prices[idx]
  if (!pr) return
  pr.supplier_id = ''
  const q = String(pr.supplierSearch || '').trim().toLowerCase()
  if (!q) {
    pr.filteredSuppliers = []
    pr.dropdownOpen = false
    pr.dropdownIndex = 0
    return
  }

  pr.filteredSuppliers = suppliers.value
    .filter(s => String(s.nama || '').toLowerCase().includes(q))
    .slice(0, 8)
  pr.dropdownOpen = pr.filteredSuppliers.length > 0
  pr.dropdownIndex = 0

  if (pr.dropdownOpen) {
    nextTick(() => calcDropdownPos(idx))
  }
}

function onStockSupplierFocus(idx) {
  if (!isStockOnlyEdit.value) return
  const pr = form.prices[idx]
  if (!pr) return
  const q = String(pr.supplierSearch || '').trim()
  if (!q) {
    pr.dropdownOpen = false
    return
  }
  onStockSupplierInput(idx)
}

function onSupplierSearchKey(e, idx) {
  if (isIdentityOnlyEdit.value) {
    e.preventDefault()
    return
  }

  const pr = form.prices[idx]
  if (!pr) return

  if (isStockOnlyEdit.value) {
    if (e.key === 'Enter') {
      e.preventDefault()
      modal.activePriceRow = idx

      const selected = pr.filteredSuppliers?.[pr.dropdownIndex]
      if (pr.dropdownOpen && selected) {
        selectSupplier(idx, selected)
        return
      }

      const typedName = String(pr.supplierSearch || '').trim()
      if (typedName) {
        const exact = suppliers.value.find(s => normalizeNameValue(s.nama) === normalizeNameValue(typedName))
        if (exact) {
          pr.supplier_id = exact.id
          pr.supplierSearch = exact.nama
        }
      }
      nextTick(() => priceStokRefs.value[idx]?.focus())
      return
    }
    if (e.key === 'ArrowDown') {
      if (!pr.dropdownOpen && String(pr.supplierSearch || '').trim()) {
        onStockSupplierInput(idx)
      }
      if (pr.dropdownOpen) {
        e.preventDefault()
        pr.dropdownIndex = Math.min((pr.dropdownIndex ?? 0) + 1, (pr.filteredSuppliers?.length ?? 1) - 1)
      }
      return
    }
    if (e.key === 'ArrowUp') {
      if (pr.dropdownOpen) {
        e.preventDefault()
        pr.dropdownIndex = Math.max((pr.dropdownIndex ?? 0) - 1, 0)
      }
      return
    }
    if (e.key === 'Escape') {
      e.preventDefault()
      pr.dropdownOpen = false
      return
    }
    return
  }

  if (e.key === 'ArrowDown') {
    e.preventDefault()
    pr.dropdownIndex = Math.min((pr.dropdownIndex ?? 0) + 1, (pr.filteredSuppliers?.length ?? 1) - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    pr.dropdownIndex = Math.max((pr.dropdownIndex ?? 0) - 1, 0)
  } else if (e.key === 'Enter') {
    e.preventDefault()
    const selected = pr.filteredSuppliers?.[pr.dropdownIndex]
    if (pr.dropdownOpen && selected) {
      selectSupplier(idx, selected)
    } else {
      priceStokRefs.value[idx]?.focus()
    }
  } else if (e.key === 'Escape') {
    e.preventDefault(); pr.dropdownOpen = false
  } else if (e.key === 'Tab') {
    pr.dropdownOpen = false
  }
}

function focusPriceHarga(idx) { priceHargaRefs.value[idx]?.focus() }

function onHargaEnter(idx) {
  if (isIdentityOnlyEdit.value) {
    btnSave.value?.focus()
    return
  }

  if (isStockOnlyEdit.value) {
    if (idx < form.prices.length - 1) {
      modal.activePriceRow = idx + 1
      nextTick(() => priceSupplierRefs.value[idx + 1]?.focus())
    } else {
      nextTick(() => stockTanggalRef.value?.focus())
    }
    return
  }

  if (idx < form.prices.length - 1) {
    modal.activePriceRow = idx + 1
    nextTick(() => priceSupplierRefs.value[idx + 1]?.focus())
  } else {
    addPriceRow()
  }
}

// -- Foto upload --------------------------------------------
async function compressImage(file, maxSizeKB = 150, maxWidth = 800) {
  if (file.size / 1024 <= maxSizeKB) return file
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onerror = () => reject(new Error('Gagal membaca file'))
    reader.onload = (e) => {
      const img = new Image()
      img.onerror = () => reject(new Error('Gagal memproses gambar'))
      img.onload = () => {
        const canvas = document.createElement('canvas')
        let w = img.width, h = img.height
        if (w > maxWidth) { h = Math.round(h * maxWidth / w); w = maxWidth }
        canvas.width = w; canvas.height = h
        canvas.getContext('2d').drawImage(img, 0, 0, w, h)
        const ratio = (maxSizeKB * 1024) / file.size
        const q1 = Math.min(0.82, Math.max(0.4, Math.sqrt(ratio) * 0.9))
        canvas.toBlob((blob) => {
          if (!blob) { resolve(file); return }
          if (blob.size / 1024 <= maxSizeKB || q1 <= 0.4) {
            resolve(new File([blob], file.name, { type: 'image/jpeg', lastModified: Date.now() }))
          } else {
            const q2 = Math.max(0.35, q1 * (maxSizeKB * 1024 / blob.size) * 0.85)
            canvas.toBlob((blob2) => {
              resolve(new File([blob2 || blob], file.name, { type: 'image/jpeg', lastModified: Date.now() }))
            }, 'image/jpeg', q2)
          }
        }, 'image/jpeg', q1)
      }
      img.src = e.target.result
    }
    reader.readAsDataURL(file)
  })
}

function removeFoto(photo) {
  if (isStockOnlyEdit.value) return
  if (photo?.origin === 'pending') {
    const pending = pendingFotoFiles.value[photo.index]
    if (pending?.previewUrl) URL.revokeObjectURL(pending.previewUrl)
    pendingFotoFiles.value.splice(photo.index, 1)
  } else {
    form.foto_urls.splice(photo.index, 1)
  }
  if (fileInput.value) fileInput.value.value = ''
  if (fileInputCamera.value) fileInputCamera.value.value = ''
}

function removeLastFoto() {
  if (isStockOnlyEdit.value) return
  if (pendingFotoFiles.value.length > 0) {
    const last = pendingFotoFiles.value.pop()
    if (last?.previewUrl) URL.revokeObjectURL(last.previewUrl)
  } else if (form.foto_urls.length > 0) {
    form.foto_urls.splice(form.foto_urls.length - 1, 1)
    if (fileInput.value) fileInput.value.value = ''
    if (fileInputCamera.value) fileInputCamera.value.value = ''
  }
}

async function handleFileSelect(event) {
  if (isStockOnlyEdit.value) return
  const files = Array.from(event.target.files || [])
  if (files.length === 0) return
  const remainingSlots = 3 - (form.foto_urls.length + pendingFotoFiles.value.length)
  if (files.length > remainingSlots) {
    photoUpload.error = `Maksimal 3 foto. Anda hanya bisa menambah ${remainingSlots} foto lagi.`
    toast.add({ severity: 'warn', summary: 'Terlalu Banyak Foto', detail: `Maksimal 3 foto per barang.`, life: 4000 })
    setTimeout(() => { photoUpload.error = '' }, 4000)
    return
  }
  const invalidFiles = files.filter(f => !f.type.startsWith('image/'))
  if (invalidFiles.length > 0) {
    photoUpload.error = 'Hanya file gambar yang diperbolehkan.'
    toast.add({ severity: 'error', summary: 'Format File Salah', detail: 'Hanya file gambar yang diperbolehkan.', life: 4000 })
    setTimeout(() => { photoUpload.error = '' }, 4000)
    return
  }
  const MAX_SIZE = 5 * 1024 * 1024
  const oversizedFiles = files.filter(f => f.size > MAX_SIZE)
  if (oversizedFiles.length > 0) {
    photoUpload.error = 'Ukuran file maksimal 5MB.'
    toast.add({ severity: 'error', summary: 'File Terlalu Besar', detail: 'Ukuran setiap foto maksimal 5MB.', life: 4000 })
    setTimeout(() => { photoUpload.error = '' }, 4000)
    return
  }
  photoUpload.error = ''
  try {
    const compressedFiles = await Promise.all(files.map(file => compressImage(file)))
    const newPending = compressedFiles.map(file => ({
      file,
      previewUrl: URL.createObjectURL(file),
    }))
    pendingFotoFiles.value.push(...newPending)
    if (fileInput.value) fileInput.value.value = ''
    if (fileInputCamera.value) fileInputCamera.value.value = ''
    toast.add({ severity: 'info', summary: 'Foto Ditambahkan', detail: `${newPending.length} foto siap diupload saat Simpan.`, life: 2600 })
  } catch (error) {
    photoUpload.error = error.message || 'Gagal menyiapkan foto.'
    toast.add({ severity: 'error', summary: 'Foto Gagal Diproses', detail: error.message || 'Terjadi kesalahan.', life: 5000 })
  }
}

async function uploadToCloudinary(file, index, total) {
  const CLOUD_NAME  = 'dtueroxgq'
  const UPLOAD_PRESET = 'mmb_preset'
  const CLOUDINARY_URL = `https://api.cloudinary.com/v1_1/${CLOUD_NAME}/image/upload`
  const formData = new FormData()
  formData.append('file', file)
  formData.append('upload_preset', UPLOAD_PRESET)
  formData.append('folder', 'mmb-spareparts')
  const response = await fetch(CLOUDINARY_URL, { method: 'POST', body: formData })
  if (!response.ok) {
    const errorData = await response.json()
    throw new Error(errorData.error?.message || 'Upload gagal')
  }
  const data = await response.json()
  photoUpload.progress = Math.round(((index + 1) / total) * 100)
  return data.secure_url
}

async function insertStockAdjustmentHistory({
  productId,
  productKode,
  productNama,
  previousStok,
  nextStok,
  validationTanggal,
  validationStaff,
  validationAlasan,
}) {
  const stockBefore = Math.max(0, toSafeNumber(previousStok, 0))
  const stockAfter = Math.max(0, toSafeNumber(nextStok, 0))
  const qtyDelta = Number((stockAfter - stockBefore).toFixed(3))

  if (Math.abs(qtyDelta) < 0.0005) {
    return false
  }

  const { data: authData } = await supabase.auth.getUser()
  const createdBy = authData?.user?.id || null

  const payload = {
    product_id: productId || null,
    product_kode: String(productKode || '').trim(),
    product_nama: String(productNama || '').trim(),
    adjustment_date: validationTanggal,
    stock_before: stockBefore,
    stock_after: stockAfter,
    qty_delta: qtyDelta,
    staff_nama: String(validationStaff || '').trim(),
    alasan: String(validationAlasan || '').trim(),
    created_by: createdBy,
  }

  if (!payload.staff_nama) {
    throw new Error('Nama petugas yang mengubah wajib diisi.')
  }
  if (!payload.alasan) {
    throw new Error('Alasan perubahan stok wajib diisi.')
  }

  const { error } = await supabase
    .from('stock_adjustments')
    .insert(payload)

  if (error) {
    if (isMissingSupabaseTableError(error) || isMissingSupabaseColumnError(error)) {
      throw new Error('Gagal simpan histori stok karena tabel database belum tersedia. Jalankan migrasi server/schema/21_add_stock_adjustments_history.sql.')
    }
    throw error
  }

  return true
}

// -- Submit -------------------------------------------------
async function submitModal() {
  modal.saving = true; modal.error = ''
  try {
    if (isStockOnlyEdit.value) {
      if (!stockValidation.tanggal) throw new Error('Tanggal perubahan stok wajib diisi.')
      if (!stockValidation.diubahOleh.trim()) throw new Error('Nama petugas yang mengubah wajib diisi.')
      if (!stockValidation.alasan.trim()) throw new Error('Alasan perubahan stok wajib diisi.')
    }

    const shouldAutoGenerateKode = modal.mode === 'add' || !isStockOnlyEdit.value
    if (shouldAutoGenerateKode) {
      const preferredSuffix = extractKodeSuffix(form.kode) || autoKodeSuffix.value
      const generatedKode = await generateUniqueAutoKode(
        form.nama,
        modal.mode === 'edit' ? form.id : null,
        preferredSuffix,
      )
      form.kode = generatedKode
      autoKodeSuffix.value = extractKodeSuffix(generatedKode) || generateRandomKodeSuffix()
    }

    const normalizedPriceRows = buildNormalizedPriceRowsForSubmit()
    if (!normalizedPriceRows.length) {
      throw new Error('Minimal ada 1 supplier yang valid.')
    }

    const finalPriceRows = consolidatePriceRowsForSubmit(normalizedPriceRows)

    const totalStok = finalPriceRows.reduce((sum, pr) => sum + Math.max(0, toSafeNumber(pr.stok, 0)), 0)

    let previousGlobalStok = null
    let previousSupplierRows = []
    let shouldWriteStockAdjustmentHistory = false
    let supplierAdjustmentEntries = []
    if (isStockOnlyEdit.value && modal.mode === 'edit' && form.id) {
      const { data: currentProductData, error: currentProductError } = await supabase
        .from('products')
        .select('stok')
        .eq('id', form.id)
        .maybeSingle()

      if (currentProductError) throw currentProductError

      const { data: currentSupplierData, error: currentSupplierError } = await supabase
        .from('product_prices')
        .select('supplier_id, stok')
        .eq('product_id', form.id)
        .eq('aktif', true)

      if (currentSupplierError) throw currentSupplierError

      previousGlobalStok = toSafeNumber(currentProductData?.stok, toSafeNumber(form.stok, 0))
      previousSupplierRows = Array.isArray(currentSupplierData) ? currentSupplierData : []

      supplierAdjustmentEntries = buildSupplierAdjustmentEntries({
        productId: form.id,
        productKode: form.kode,
        productNama: form.nama,
        validationTanggal: stockValidation.tanggal,
        validationStaff: stockValidation.diubahOleh,
        validationAlasan: stockValidation.alasan,
        previousRows: previousSupplierRows,
        nextRows: finalPriceRows,
      })

      const delta = Number((totalStok - previousGlobalStok).toFixed(3))
      shouldWriteStockAdjustmentHistory = Math.abs(delta) >= 0.0005 || supplierAdjustmentEntries.length > 0

      if (shouldWriteStockAdjustmentHistory) {
        await ensureStockAdjustmentHistoryTable()
      }
    }

    let uploadedPendingUrls = []
    if (pendingFotoFiles.value.length > 0) {
      photoUpload.uploading = true
      photoUpload.progress = 0
      const filesToUpload = pendingFotoFiles.value.map(item => item.file)
      uploadedPendingUrls = await Promise.all(
        filesToUpload.map((file, index) => uploadToCloudinary(file, index, filesToUpload.length))
      )
    }

    const finalFotoUrls = [...form.foto_urls, ...uploadedPendingUrls].filter(Boolean)

    const payload = {
      kode: form.kode.trim(),
      nama: form.nama.trim().toUpperCase(),
      deskripsi: form.deskripsi.trim() || null,
      stok: totalStok,
      foto_urls: finalFotoUrls.length > 0 ? finalFotoUrls : null,
      aktif: true,
    }
    let productId = form.id
    if (modal.mode === 'add') {
      const { data, error } = await supabase.from('products').insert(payload).select('id').single()
      if (error) throw error
      productId = data.id
    } else {
      const { error } = await supabase.from('products').update(payload).eq('id', form.id)
      if (error) throw error
    }

    await syncProductPrices(productId, finalPriceRows)

    if (shouldWriteStockAdjustmentHistory) {
      if (supplierAdjustmentEntries.length > 0) {
        for (const entry of supplierAdjustmentEntries) {
          await insertStockAdjustmentHistory({
            ...entry,
            productId,
            productKode: payload.kode,
            productNama: payload.nama,
          })
        }
      } else {
        await insertStockAdjustmentHistory({
          productId,
          productKode: payload.kode,
          productNama: payload.nama,
          previousStok: previousGlobalStok,
          nextStok: totalStok,
          validationTanggal: stockValidation.tanggal,
          validationStaff: stockValidation.diubahOleh,
          validationAlasan: stockValidation.alasan,
        })
      }
    }

    closeModal()
    if (hasSearched.value) await doSearch()
    const baseMessage = modal.mode === 'add' ? 'Barang berhasil ditambahkan' : 'Barang berhasil diupdate'
    const stockInfo = isStockOnlyEdit.value
      ? ` | Validasi: ${stockValidation.tanggal} oleh ${stockValidation.diubahOleh.trim()} (${stockValidation.alasan.trim()})`
      : ''
    toast.add({ severity: 'success', summary: 'Berhasil', detail: baseMessage + stockInfo, life: 3000 })
  } catch (err) {
    modal.error = err.message
  } finally {
    modal.saving = false
    photoUpload.uploading = false
    photoUpload.progress = 0
  }
}

// -- Archive ------------------------------------------------
function openArchive(row) {
  if (!row) return
  archiveModal.row = row; archiveModal.saving = false; archiveModal.show = true
}

async function doArchive() {
  archiveModal.saving = true
  try {
    const { error } = await supabase
      .from('products').update({ is_archived: true }).eq('id', archiveModal.row.product_id)
    if (error) throw error
    archiveModal.show = false
    if (hasSearched.value) await doSearch()
    toast.add({ severity: 'success', summary: 'Diarsipkan', detail: `${archiveModal.row.nama} berhasil diarsipkan.`, life: 3000 })
  } catch (err) {
    console.error(err)
  } finally {
    archiveModal.saving = false
  }
}



// -- Lightbox -----------------------------------------------
function openPhotoLightbox(index) {
  if (!selectedRowData.value?.foto_urls?.length) return
  lightbox.photos = selectedRowData.value.foto_urls
  lightbox.currentIndex = index
  lightbox.show = true
}
function closeLightbox() { lightbox.show = false; lightbox.photos = []; lightbox.currentIndex = 0 }
function prevPhoto() { if (lightbox.currentIndex > 0) lightbox.currentIndex-- }
function nextPhoto() { if (lightbox.currentIndex < lightbox.photos.length - 1) lightbox.currentIndex++ }

// -- Keyboard -----------------------------------------------
function onBarangKey(e) {
  if (e.key === 'Enter') {
    e.preventDefault(); openBarangModal()
  } else if (e.key === 'ArrowDown' && hasSearched.value) {
    e.preventDefault(); e.stopPropagation()
    inputBarang.value?.blur(); moveRow(0)
  } else if (e.key === 'Escape') {
    e.preventDefault(); e.stopPropagation()
    if (hasSearched.value) { clearBarang() }
    else if (!searchBarang.value.trim()) { router.push('/gudang') }
    else { searchBarang.value = '' }
  }
}

function onGlobalKey(e) {
  if (lightbox.show) {
    if (e.key === 'Escape')           { e.preventDefault(); closeLightbox() }
    else if (e.key === 'ArrowLeft')   { e.preventDefault(); prevPhoto() }
    else if (e.key === 'ArrowRight')  { e.preventDefault(); nextPhoto() }
    return
  }
  if (editModeModal.show) {
    if (e.key === 'ArrowRight' || e.key === 'ArrowLeft' || e.key === 'F1' || e.key === 'F2' || e.key === 'Enter' || e.key === 'Escape') {
      onEditModeModalKeydown(e)
    }
    return
  }
  if (modal.show || archiveModal.show || barangModal.show) return

  switch (e.key) {
    case 'F1':
      e.preventDefault()
      if (selectedRowData.value?.foto_urls?.length > 0) { openPhotoLightbox(0) }
      else { inputBarang.value?.focus() }
      break
    case 'F4':
      if (selectedRowIndex.value >= 0) { e.preventDefault(); openEditModeModal(pagedRows.value[selectedRowIndex.value]) }
      break
    case 'Enter':
      if (hasSearched.value && selectedRowIndex.value >= 0 && !e.target.matches('input,textarea,select')) {
        e.preventDefault(); openEditModeModal(pagedRows.value[selectedRowIndex.value])
      }
      break
    case 'Delete':
      if (hasSearched.value && selectedRowIndex.value >= 0 && !e.target.matches('input,textarea,select')) {
        e.preventDefault(); openArchive(pagedRows.value[selectedRowIndex.value])
      }
      break
    case 'ArrowDown':
      if (hasSearched.value && !e.target.matches('input,textarea,select')) {
        e.preventDefault(); e.stopPropagation(); moveRow(1)
      }
      break
    case 'ArrowUp':
      if (hasSearched.value && !e.target.matches('input,textarea,select')) {
        e.preventDefault(); e.stopPropagation(); moveRow(-1)
      }
      break
    case 'PageDown': e.preventDefault(); nextPage(); break
    case 'PageUp':   e.preventDefault(); prevPage(); break
    case 'Escape':
      e.preventDefault(); e.stopPropagation()
      if (hasSearched.value) { clearBarang(); nextTick(() => inputBarang.value?.focus()) }
      else { router.push('/gudang') }
      break
    case 'F2':
      e.preventDefault(); openAdd()
      break
  }
}

function onGlobalEscModal(e) {
  if (e.key !== 'Escape') return
  if (archiveModal.show) { archiveModal.show = false }
  else if (modal.show)  { closeModal({ backToChoice: true }) }
  else if (editModeModal.show) { closeEditModeModal() }
}

function onLightboxKey(e) {
  if (!lightbox.show) return
  if (e.key === 'Escape')          { closeLightbox() }
  else if (e.key === 'ArrowLeft')  { prevPhoto() }
  else if (e.key === 'ArrowRight') { nextPhoto() }
}

function getSelectedCatalogProductId() {
  if (selectedRowIndex.value < 0) return null
  return pagedRows.value[selectedRowIndex.value]?.product_id ?? null
}

function serializeFormPrices(prices) {
  if (!Array.isArray(prices)) return []

  return prices.map(pr => ({
    price_id: pr?.price_id ?? null,
    supplier_id: pr?.supplier_id || '',
    supplierSearch: pr?.supplierSearch || '',
    stok: Number(pr?.stok ?? 0),
    harga_beli: Number(pr?.harga_beli ?? 0),
  }))
}

function persistKatalogState() {
  sessionStorage.removeItem(GUDANG_KATALOG_STATE_KEY)
}

function restoreKatalogState() {
  sessionStorage.removeItem(GUDANG_KATALOG_STATE_KEY)
  return null
}

function applyKatalogSelection(productId) {
  if (!productId) return

  const globalIndex = allRows.value.findIndex(
    row => String(row.product_id) === String(productId)
  )
  if (globalIndex < 0) return

  currentPage.value = Math.floor(globalIndex / PAGE_SIZE) + 1
  selectedRowIndex.value = globalIndex % PAGE_SIZE

  nextTick(() => rowRefs.get(selectedRowIndex.value)?.scrollIntoView({ block: 'nearest' }))
}

function restoreKatalogModalFromState(restored) {
  if (!restored) return

  if (restored.modal?.show && restored.form) {
    const restoredPrices = Array.isArray(restored.form.prices) ? restored.form.prices : []

    form.id = restored.form.id ?? null
    form.kode = restored.form.kode || ''
    form.nama = restored.form.nama || ''
    form.deskripsi = restored.form.deskripsi || ''
    form.stok = Number(restored.form.stok ?? 0)
    form.satuan = restored.form.satuan || 'pcs'
    form.foto_urls = Array.isArray(restored.form.foto_urls)
      ? restored.form.foto_urls.filter(Boolean)
      : []
    form.prices = restoredPrices.length
      ? restoredPrices.map(pr =>
          makePriceRowDefault({
            price_id: pr?.price_id ?? null,
            supplier_id: pr?.supplier_id || '',
            supplierSearch: pr?.supplierSearch || '',
            stok: Number(pr?.stok ?? 0),
            harga_beli: Number(pr?.harga_beli ?? 0),
          })
        )
      : [makePriceRowDefault()]

    modal.mode = restored.modal.mode === 'edit' ? 'edit' : 'add'
    modal.variant = ['full', 'identity', 'stock'].includes(restored.modal.variant)
      ? restored.modal.variant
      : 'full'
    modal.title = typeof restored.modal.title === 'string' && restored.modal.title
      ? restored.modal.title
      : (modal.mode === 'add' ? 'Tambah Barang Baru' : 'Edit Barang')
    modal.error = ''

    const restoredActiveRow = Number.isInteger(restored.modal.activePriceRow)
      ? restored.modal.activePriceRow
      : 0
    modal.activePriceRow = Math.min(
      Math.max(restoredActiveRow, 0),
      Math.max(form.prices.length - 1, 0)
    )

    stockValidation.tanggal = restored.stockValidation?.tanggal || ''
    stockValidation.diubahOleh = restored.stockValidation?.diubahOleh || ''
    stockValidation.alasan = restored.stockValidation?.alasan || ''

    modal.show = true
    nextTick(() => {
      if (isStockOnlyEdit.value) {
        priceSupplierRefs.value[modal.activePriceRow]?.focus() || stockTanggalRef.value?.focus()
      } else {
        inputKode.value?.focus()
      }
    })
    return
  }

  if (restored.editModeModal?.show && restored.editModeModal.rowProductId != null) {
    const row = allRows.value.find(
      item => String(item.product_id) === String(restored.editModeModal.rowProductId)
    )
    if (row) {
      openEditModeModal(row)
      editModeModal.selected = restored.editModeModal.selected === 1 ? 1 : 0
    }
  }
}

// -- Lifecycle ----------------------------------------------
onMounted(async () => {
  window.addEventListener('keydown', onGlobalKey)
  window.addEventListener('keydown', onGlobalEscModal)
  window.addEventListener('keydown', onLightboxKey)

  await loadSuppliers()
  try {
    await autoNormalizeLegacyProductCodes()
  } catch (normalizeError) {
    console.error('[autoNormalizeLegacyProductCodes]', normalizeError)
  }
  restoreKatalogState()
  clearBarang()
  resetForm()
  modal.show = false
  editModeModal.show = false
  nextTick(() => inputBarang.value?.focus())
})

onUnmounted(() => {
  sessionStorage.removeItem(GUDANG_KATALOG_STATE_KEY)
  window.removeEventListener('keydown', onGlobalKey)
  window.removeEventListener('keydown', onGlobalEscModal)
  window.removeEventListener('keydown', onLightboxKey)
  clearPendingFotoFiles()
})

watch(allRows, () => { currentPage.value = 1 })

watch([searchBarang, hasSearched, lastSearch, currentPage, selectedRowIndex], () => {
  persistKatalogState()
})

watch(
  [
    () => modal.show,
    () => modal.mode,
    () => modal.variant,
    () => modal.title,
    () => modal.activePriceRow,
    () => editModeModal.show,
    () => editModeModal.selected,
    () => editModeModal.row?.product_id ?? null,
  ],
  () => {
    persistKatalogState()
  }
)

watch(form, () => {
  if (modal.show) {
    persistKatalogState()
  }
}, { deep: true })

watch(stockValidation, () => {
  if (modal.show) {
    persistKatalogState()
  }
}, { deep: true })

watch(() => form.nama, () => {
  if (!modal.show || isStockOnlyEdit.value) return
  syncAutoGeneratedKodePreview()
})
</script>

<style scoped>
@import '@/assets/Styles/gudang/gudang-katalog-page.css';
</style>
