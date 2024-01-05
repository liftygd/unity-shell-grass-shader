using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShellGenerator : MonoBehaviour
{
    public Mesh shellMesh;
    public Shader baseShader;

    public bool update = true;

    [Range(1, 256)] public int shellCount = 16;

    [Range(0f, 1f)] public float shellHeightDifference = 0.5f;

    [Range(1f, 50f)] public float shellHeightThreshold = 20;

    [Range(1f, 1.5f)] public float heightValueChange = 1.5f;

    [Header("Textures")] 
    [SerializeField] private Texture highlightTexture;

    [Header("Colors")] 
    [SerializeField] [ColorUsage(true, true)] private Color mainColor;
    [SerializeField] [ColorUsage(true, true)] private Color highlightColor;

    [Header("Noise")] [SerializeField] private float noiseSize;
    [SerializeField] private Vector4 noiseOffset;
    [Range(0f, 10f)] [SerializeField] private float noisePower;
    [Range(0f, 1f)] [SerializeField] private float cutoff;

    [Header("Wind")] [SerializeField] private Vector4 windDirection;
    [SerializeField] private float windSpeed;
    [Range(0.5f, 2f)] [SerializeField] private float windHeight;

    [Header("Roundness")] 
    [Range(0f, 1f)] [SerializeField] private float circleRadius;

    [Range(0f, 1f)] [SerializeField] private float circleRadiusByHeight;

    private Material _shellMaterial;
    private GameObject[] _shells;

    private void OnEnable()
    {
        ClearChildren();
        GenerateShells();
    }

    private void ClearChildren()
    {
        _shells = Array.Empty<GameObject>();
        
        for (int i = 0; i < transform.childCount; i++)
        {
            Destroy(transform.GetChild(i).gameObject);
        }
    }

    [ContextMenu("Update Shell Array")]
    private void UpdateChildren()
    {
        _shells = new GameObject[transform.childCount];

        for (int i = 0; i < transform.childCount; i++)
        {
            _shells[i] = transform.GetChild(i).gameObject;
        }
    }

    [ContextMenu("Generate")]
    private void GenerateShells()
    {
        _shells = new GameObject[shellCount];

        for (int i = 0; i < shellCount; ++i) {
            _shells[i] = new GameObject("Shell " + i);

            _shells[i].AddComponent<MeshFilter>();
            _shells[i].AddComponent<MeshRenderer>();

            _shells[i].GetComponent<MeshFilter>().mesh = shellMesh;
            _shells[i].transform.SetParent(transform, false);
            _shells[i].GetComponent<MeshRenderer>().material = new Material(baseShader);
            
            ApplyVariablesToMaterial(_shells[i], i);
        }
    }

    private void UpdateMaterials()
    {
        for (int i = 0; i < shellCount; ++i) {
            ApplyVariablesToMaterial(_shells[i], i);
        }
    }

    private void ApplyVariablesToMaterial(GameObject shell, int shellIndex)
    {
        shell.transform.localPosition = Vector3.zero;
        shell.transform.localPosition += new Vector3(0, shellIndex * shellHeightDifference * 0.25f, 0);

        _shellMaterial = shell.GetComponent<MeshRenderer>().material;
        _shellMaterial.SetFloat("_HeightValue", shellIndex / shellHeightThreshold - heightValueChange);
        _shellMaterial.SetTexture("_HighlightPattern", highlightTexture);
                
        _shellMaterial.SetColor("_MainCol", mainColor);
        _shellMaterial.SetColor("_SecondaryCol", highlightColor);
                
        _shellMaterial.SetFloat("_NoiseSize", noiseSize);
        _shellMaterial.SetVector("_NoiseOffset", noiseOffset);
        _shellMaterial.SetFloat("_NoisePower", noisePower);
        _shellMaterial.SetFloat("_Cutoff", cutoff);
                
        _shellMaterial.SetVector("_WindDirection", windDirection);
        _shellMaterial.SetFloat("_WindSpeed", windSpeed);
        _shellMaterial.SetFloat("_WindHeight", windHeight);
                
        _shellMaterial.SetFloat("_CircleRadius", circleRadius);
        _shellMaterial.SetFloat("_CircleRadiusHeightChange", circleRadiusByHeight);

        shell.GetComponent<MeshRenderer>().material = _shellMaterial;
    }

    private void OnValidate()
    {
        if (!update) return;
        
        try
        {
            UpdateMaterials();
        }
        catch
        {
            UpdateChildren();
        }
    }
}
