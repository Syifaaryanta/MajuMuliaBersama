import ExcelJS from 'exceljs'

const BORDER_THIN = {
  top: { style: 'thin' },
  left: { style: 'thin' },
  bottom: { style: 'thin' },
  right: { style: 'thin' },
}

function applyBorders(worksheet) {
  worksheet.eachRow({ includeEmpty: true }, row => {
    row.eachCell({ includeEmpty: true }, cell => {
      cell.border = BORDER_THIN
    })
  })
}

function applyHeaderStyle(worksheet, headerRowIndex) {
  const headerRow = worksheet.getRow(headerRowIndex)
  headerRow.font = { bold: true }
  headerRow.alignment = { vertical: 'middle', horizontal: 'center' }
}

function applyTitleStyle(worksheet, titleRowIndex, columnCount) {
  const titleRow = worksheet.getRow(titleRowIndex)
  titleRow.font = { bold: true, size: 14 }
  titleRow.alignment = { vertical: 'middle', horizontal: 'left' }
  if (columnCount > 1) {
    worksheet.mergeCells(titleRowIndex, 1, titleRowIndex, columnCount)
  }
}

function normalizeColumns(columns) {
  return columns.map(col => ({
    header: col.header,
    key: col.key,
    width: col.width || 18,
  }))
}

export async function exportWorkbook({ fileName, sheets }) {
  const workbook = new ExcelJS.Workbook()

  sheets.forEach(sheet => {
    const worksheet = workbook.addWorksheet(sheet.name)
    const columns = normalizeColumns(sheet.columns)
    worksheet.columns = columns.map(col => ({ key: col.key, width: col.width }))

    const titleText = sheet.title || sheet.name
    worksheet.addRow([titleText])
    worksheet.addRow([])
    worksheet.addRow(columns.map(col => col.header))
    worksheet.addRows(sheet.rows)

    applyTitleStyle(worksheet, 1, columns.length)
    applyHeaderStyle(worksheet, 3)
    applyBorders(worksheet)
  })

  const buffer = await workbook.xlsx.writeBuffer()
  const blob = new Blob([buffer], {
    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  })

  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `${fileName}.xlsx`
  document.body.appendChild(link)
  link.click()
  link.remove()
  URL.revokeObjectURL(url)
}
