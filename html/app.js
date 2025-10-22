const Nui = (action, data) => fetch(`https://${GetParentResourceName()}/${action}`, {
  method: 'POST',
  headers: {'Content-Type':'application/json'},
  body: JSON.stringify(data || {})
});

const $ = q => document.querySelector(q);
const list = $('#list');
const statusEl = $('#status');
const app = $('.ui');

let hidden = false;

window.addEventListener('message', (evt) => {
  const data = evt.data;
  if (!data || !data.action) return;

  if (data.action === 'open') {
    document.body.style.display = 'block';
  }
  else if (data.action === 'close') {
    document.body.style.display = 'none';
  }
  else if (data.action === 'status') {
    statusEl.textContent = `Cinematic: ${data.cinematic ? 'ON' : 'OFF'}`;
    $('#btnCine').textContent = data.cinematic ? 'Normal View' : 'Cinematic';
  }
  else if (data.action === 'planeList:add') {
    addPlaneCard(data.plane.netId, data.plane.kind);
  }
  else if (data.action === 'planeList:remove') {
    const el = document.getElementById(`plane-${data.netId}`);
    if (el) el.remove();
  }
});

function addPlaneCard(netId, kind) {
  const card = document.createElement('div');
  card.className = 'card';
  card.id = `plane-${netId}`;
  card.innerHTML = `
    <div><strong>#${netId}</strong> &nbsp;<span class="badge ${kind}">${kind}</span></div>
    <div class="actions">
      ${kind === 'arrival'
        ? `<button data-cmd="land">Clear to Land</button>
           <button data-cmd="taxi">Taxi to Hangar</button>`
        : `<button data-cmd="hold">Hold</button>
           <button data-cmd="takeoff">Clear Takeoff</button>`
      }
      <button data-cmd="hold">Hold</button>
    </div>
  `;
  card.addEventListener('click', (e) => {
    const btn = e.target.closest('button');
    if (!btn) return;
    Nui('commandPlane', { netId, command: btn.dataset.cmd });
  });
  list.prepend(card);
}

$('#btnClose').addEventListener('click', () => Nui('close'));
$('#btnCine').addEventListener('click', () => Nui('toggleCinematic'));
$('#btnHide').addEventListener('click', () => {
  hidden = !hidden;
  app.classList.toggle('hidden', hidden);
  Nui('toggleUI', {});
});

$('#btnArr').addEventListener('click', () => Nui('requestArrival'));
$('#btnDep').addEventListener('click', () => Nui('requestDeparture'));

// Start hidden until opened
document.body.style.display = 'none';
